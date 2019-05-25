//
//  CollectionView.swift
//  Suit
//
//  Created by pmacro on 15/01/2017.
//
//

import Foundation

///
/// The options for how a ListView acts whenever its cells are highlighted.
///
public enum HighlightingBehavior {
  /// Highlighting is not supported at all.
  case none
  
  /// Only one item can be highlighted at a given time.  Highlighting a new item de-highlights
  /// the old item.
  case single
  
  /// Multiple items can be highlighted at a time.  Un-highlighting occurs when the item highlighting
  /// action happens again.
  case multi
}

public protocol ListViewDelegate {
  func didHighlight(itemAt indexPath: IndexPath)
  func didRemoveHighlight(onItemAt indexPath: IndexPath)
  func didSelect(itemAt indexPath: IndexPath)
}

public protocol ListViewDatasource {
  func numberOfSections() -> Int
  func numberOfItemsInSection(section: Int) -> Int
  func cellForItem(at indexPath: IndexPath, withState: ListItemState) -> ListViewCell
  func heightOfCell(at indexPath: IndexPath) -> CGFloat
}

public struct ListItemState {
  public let isHighlighted: Bool
}

public class ListView: View {
  
  public var highlightingBehaviour: HighlightingBehavior = .single
  public var highlightedChildren = [IndexPath]()
  public var delegate: ListViewDelegate?
  
  /// This property only has an effect when highlightingBehavior is `single`.
  public var highlightsOnRollover = false
  
  open var datasource: ListViewDatasource? {
    didSet {
      (superview as? ScrollView)?.contentsDidChange()
    }
  }
  
  /// If true, the delegate will be informed of selection after either one or two presses
  /// of a cell.  The `selectsOnSinglePress` property determines whether one or two presses
  /// on a cell triggers selection.
  public var isSelectable = false
  
  /// Is the collection view is selectable, this property configures whether one or two presses
  /// triggers selection.  Selection causes the delegate's `didSelect(itemAt:)` method and the
  /// onSelection closure to be invoked.
  public var selectsOnSinglePress = false
  
  public var onSelection: ((IndexPath, ListViewCell) -> Void)?
  public var onHighlight: ((IndexPath, ListViewCell) -> Void)?
  public var onRemoveHighlight: ((IndexPath, View) -> Void)?
  
  public var focusedCellIndex: IndexPath?
  
  public var animateSelections = true
  
  public var selectionKeys: [KeyType]?
  
  private var visibleCellIndices: [IndexPath]?
  private var indexToFrameCache = [IndexPath: CGRect]()
  
  private var isScrollable: Bool {
    if let embeddingScrollView = embeddingScrollView {
      return embeddingScrollView.frame.height < frame.height
    }
    return false
  }
  
  override func didScroll(to rect: CGRect) {
    super.didScroll(to: rect)
    showCells(in: rect)
  }
  
  public override func didAttachToWindow() {
    super.didAttachToWindow()
    showCells(in: embeddingScrollView?.bounds ?? bounds)
  }
  
  func showCells(in rect: CGRect) {
    visibleCellIndices = calculateVisibleCellIndices(in: rect)

    guard let datasource = datasource,
          let indices = visibleCellIndices else { return }
    
    subviews.removeAll()
    
    let currentX = rect.origin.x
    var currentY = frame.origin.y - rect.origin.y
    var isFirstVisibleCell = true
    
    for section in 0..<datasource.numberOfSections() {
      for item in 0..<datasource.numberOfItemsInSection(section: section) {
        
        let indexPath = IndexPath(item: item, section: section)
        let cellHeight = datasource.heightOfCell(at: indexPath)
        
        if indices.contains(indexPath) {
          
          // For the first cell we're displaying we need to adjust the 'currentY'
          // otherwise it'd only ever show the full height of an individual cell.
          // In other words, the result of this is to have partial cell visibility when
          // scrolling, as opposed to whole-cell scroll increments.
          if isFirstVisibleCell {
            isFirstVisibleCell = false
            currentY -= currentY - (indexToFrameCache[indexPath]?.origin.y ?? 0)
          }
          
          let isHighlighted = highlightedChildren.contains(indexPath)
          let cell = datasource.cellForItem(at: indexPath,
                                            withState: ListItemState(isHighlighted: isHighlighted))
          cell.positionType = .absolute
          cell.set(position: currentY~, for: .top)
          cell.set(position: currentX~, for: .left)
          cell.isHighlighted = isHighlighted
          cell.indexPath = indexPath
          cell.height = cellHeight~
          add(subview: cell)
          cell.updateAppearance(style: Appearance.current)
          currentY += cellHeight
        }
      }
    }
    
    resizeToFitContent()
    window.rootView.invalidateLayout()
    forceRedraw()
  }
    
  func calculateVisibleCellIndices(in rect: CGRect) -> [IndexPath] {
    guard let datasource = datasource else {
      return []
    }
    
    let topY = -rect.origin.y
    let bottomY = topY + rect.height
    
    var currentY: CGFloat = 0
    var indices: [IndexPath] = []
    
    for section in 0..<datasource.numberOfSections() {
      for item in 0..<datasource.numberOfItemsInSection(section: section) {
        let indexPath = IndexPath(item: item, section: section)
        
        currentY += datasource.heightOfCell(at: indexPath)
        
        if currentY > topY {
          indices.append(indexPath)
        }

        if currentY > bottomY {
          return indices
        }
      }
    }
    
    return indices
  }
  
  func resizeToFitContent() {
    guard let datasource = datasource else { return }
    
    var height: CGFloat = 0
    
    for section in 0..<datasource.numberOfSections() {
      for item in 0..<datasource.numberOfItemsInSection(section: section) {
        let indexPath = IndexPath(item: item, section: section)
        let cellHeight = datasource.heightOfCell(at: indexPath)
        
        indexToFrameCache[indexPath] = CGRect(x: 0,
                                              y: height,
                                              width: frame.width,
                                              height: cellHeight)
        
        height += cellHeight
      }
    }
    
    self.height = height~
  }
  
  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    let wasConsumed = super.onPointerEvent(pointerEvent)
    
    if wasConsumed {
      return wasConsumed
    }
    
    // Return if no selection behaviour is defined.
    guard highlightingBehaviour != .none else { return wasConsumed }
    
    if pointerEvent.type == .click {
      var point = windowCoordinatesInViewSpace(from: pointerEvent.location)
      point.y -= frame.origin.y
      point.x -= frame.origin.x
      if let child = findChild(atPoint: point) {
        respondToMouseClick(onCell: child)
      }
    }
    else if pointerEvent.type == .move,
            highlightingBehaviour == .single,
            highlightsOnRollover
    {
      var point = windowCoordinatesInViewSpace(from: pointerEvent.location)
      point.y -= frame.origin.y
      point.x -= frame.origin.x
      if let child = findChild(atPoint: point),
        let indexPath = child.indexPath {
        
        if !highlightedChildren.contains(indexPath) {
          highlightedChildren.forEach { [weak self] in
            if let oldChild = self?.findChild(atIndexPath: $0) {
              oldChild.isHighlighted = false
              self?.onRemoveHighlight?($0, oldChild)
              self?.delegate?.didRemoveHighlight(onItemAt: indexPath)
              oldChild.updateAppearance(style: Appearance.current)
            }
          }
          highlightedChildren.removeAll()
          highlightedChildren.append(indexPath)
          child.isHighlighted = true
          onHighlight?(indexPath, child)
          focusedCellIndex = indexPath
          delegate?.didHighlight(itemAt: indexPath)
          child.updateAppearance(style: Appearance.current)
          forceRedraw()
        }
      }
    }
    
    return false
  }
  
  func respondToMouseClick(onCell cell: ListViewCell) {
    guard let index = subviews.firstIndex(of: cell),
    let indexPath = visibleCellIndices?[index] else { return }
    
    // The cell is already highlighted.  We now either remove the highlighting, or select
    // the cell.
    if let index = highlightedChildren.firstIndex(of: indexPath) {
      if isSelectable {
        delegate?.didSelect(itemAt: indexPath)
        onSelection?(indexPath, cell)
      } else {
        highlightedChildren.remove(at: index)
      
        // Inform the delegate.
        delegate?.didRemoveHighlight(onItemAt: indexPath)
        onRemoveHighlight?(indexPath, cell)
      }
    // Highlight the child
    } else {
      // If in single-highlight mode, remove any already-highlighted children.
      if highlightingBehaviour == .single, !highlightedChildren.isEmpty {
        for i in 0..<highlightedChildren.count {
          let removedIndexPath = highlightedChildren.remove(at: i)
          
          // Inform the delegate.
          delegate?.didRemoveHighlight(onItemAt: removedIndexPath)
          if let index = visibleCellIndices?.firstIndex(of: removedIndexPath) {
            if let cell = subviews[safe: index] as? ListViewCell {
              cell.isHighlighted = false
              onRemoveHighlight?(removedIndexPath, cell)
              cell.updateAppearance(style: Appearance.current)
            }
          }
        }
      }
      
      highlightedChildren.append(indexPath)
      focusedCellIndex = indexPath
      cell.isHighlighted = true
      delegate?.didHighlight(itemAt: indexPath)
      onHighlight?(indexPath, cell)
      cell.updateAppearance(style: Appearance.current)

      // It counts as a selection on these conditions.
      if isSelectable, selectsOnSinglePress {
        // Draw the highlight first.
        window.redrawManager.redraw(view: self)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1)
        { [weak self] in
          self?.delegate?.didSelect(itemAt: indexPath)
          self?.onSelection?(indexPath, cell)
        }
      }
    }
    forceRedraw()
  }
  
  override func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    if super.onKeyEvent(keyEvent) {
      return true
    }
    
    guard case keyEvent.strokeType = KeyStrokeType.down else { return false }
    switch keyEvent.keyType {
    case .downArrow:
      let index: IndexPath
      if let focusedCellIndex = focusedCellIndex {
        index = IndexPath(item: focusedCellIndex.item + 1, section: focusedCellIndex.section)
      } else {
        index = IndexPath(item: 0, section: 0)
      }

      guard isValid(indexPath: index) else { return true }

      if visibleCellIndices?.contains(index) == false {
        if visibleCellIndices?.isEmpty == false {
          visibleCellIndices?.remove(at: 0)
        }
        visibleCellIndices?.append(index)
      }
      
      if let cell = findChild(atIndexPath: index) {
        respondToMouseClick(onCell: cell)
      }
      
      scrollTo(itemAt: index)
    case .upArrow:
      let index: IndexPath
      if let focusedCellIndex = focusedCellIndex {
        index = IndexPath(item: focusedCellIndex.item - 1, section: focusedCellIndex.section)
      } else {
        index = IndexPath(item: 0, section: 0)
      }
      
      guard isValid(indexPath: index) else { return true }
      
      if let cell = findChild(atIndexPath: index) {
        respondToMouseClick(onCell: cell)
      }
      scrollTo(itemAt: index)
    case _ where selectionKeys?.contains(keyEvent.keyType) == true:
      if isSelectable,
        let indexPath = focusedCellIndex,
        let cell = findChild(atIndexPath: indexPath) {
        delegate?.didSelect(itemAt: indexPath)
        onSelection?(indexPath, cell)
        window.redrawManager.redraw(view: self)
      }
    default:
      break
    }
    
    return true
  }
  
  func isValid(indexPath: IndexPath) -> Bool {
    guard let datasource = datasource else { return false }
    return indexPath.section < datasource.numberOfSections()
      && indexPath.item < datasource.numberOfItemsInSection(section: indexPath.section)
      && indexPath.section >= 0
      && indexPath.item >= 0
  }
  
  func findChild(atPoint point: CGPoint) -> ListViewCell? {
    for child in subviews {
      // TODO binary search
      if child.frame.contains(point) {
        return child as? ListViewCell
      }
    }
    return nil
  }
  
  func findChild(atIndexPath indexPath: IndexPath) -> ListViewCell? {
    if let index = visibleCellIndices?.firstIndex(of: indexPath) {
      return subviews[index] as? ListViewCell
    }
    return nil
  }
  
  func scrollTo(itemAt indexPath: IndexPath) {
    guard let itemRect = indexToFrameCache[indexPath] else { return }
    scrollTo(rect: itemRect)
  }
  
  func scrollTo(rect: CGRect) {
    guard isScrollable, let scrollView = embeddingScrollView else { return }
    let yAdjustment =  -rect.origin.y - rect.height + scrollView.frame.height
    
    scrollView.yOffsetTotal = min(0, yAdjustment)
    scrollView.performScrollLayoutUpdates(view: self)
    window.redrawManager.redraw(view: scrollView)
  }
}

#if os(Linux)
extension IndexPath {
  public var section: Int {
    return self[0]
  }
  
  public var item: Int {
    return self[1]
  }
  
  public init(item: Int, section: Int) {
    self.init(indexes: [section, item])
  }
} 
#endif
