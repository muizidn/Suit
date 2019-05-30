//
//  TreeComponent.swift
//  Suit
//
//  Created by pmacro on 14/06/2018.
//

import Foundation

public protocol TreeViewItem: class {
    
  /// Used to track whether this item is expanded or not.
  var isExpanded: Bool { get set }
  
  /// The item's children.  For large trees, it's generally best to lazily load the data returned by this
  /// property rather than load it up front.
  var children: [TreeViewItem]? { get set }
  
  /// This property is checked before the children property is accessed.  This computation
  /// behind this property should be quick, since the performance of the tree depends on it.
  var hasChildren: Bool { get }
  
  /// Indicates whether or not the item is currently highlighted within the tree view.
  var isHighlighted: Bool { get set }
  
  /// The view that represents this item.  If this is nil, the children are
  /// inserted at the current level, rather than nested.  This property should be nil
  /// for the root item.
  var itemView: View? { get }
}

public protocol TreeViewDataSource {
  
  ///
  /// Retrieves the cells of a parent cell.  For the root, parent cell will be nil.
  ///
  func getRootTreeViewItem() -> TreeViewItem?
}

///
/// A component that lists a hierarchy of TreeViewItems in a tree structure, with
/// collapsable and expandable items, and selection callbacks.
///
open class TreeComponent: Component, TreeViewDataSource {
  open var treeView: TreeView?
  public var nodeIndentation: CGFloat = 5
  weak var selectedItem: TreeViewItem?
  
  public var datasource: TreeViewDataSource? {
    didSet {
      reload()
    }
  }
  
  override open func loadView() {
    view = ScrollView()
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    treeView = TreeView()
    view.add(subview: treeView!)
    treeView?.width = 200~
    treeView?.flexDirection = .column
    datasource = self
  }
  
  open func reload() {
    guard let treeView = treeView else { return }
    
    treeView.subviews.forEach { $0.removeFromSuperview() }
    
    guard let datasource = datasource else {
      return
    }
    
    if let headerView = treeView.headerView {
      treeView.add(subview: headerView)
    }
    
    if let item = datasource.getRootTreeViewItem() {
      add(from: item)
    }

    if let footerView = treeView.footerView {
      treeView.add(subview: footerView)
    }
    
    treeView.window?.rootView.invalidateLayout()
    (view as? ScrollView)?.contentsDidChange()
    view.forceRedraw()
  }

  func add(from treeViewItem: TreeViewItem, level: Int = 1) {
    if let itemView = treeViewItem.itemView {
      let wrapperIndentation = CGFloat(level) * nodeIndentation
      var itemIndentation: CGFloat = 0
      
      let wrapperView = Button()
      wrapperView.flexDirection = .row
      wrapperView.alignItems = .center
      
      wrapperView.onPress = { [weak self, weak treeViewItem] in
        func getWrapperView(for item: TreeViewItem) -> View? {
          return item.itemView?.superview
        }
        
        if true == treeViewItem?.hasChildren {
          treeViewItem?.isExpanded.toggle()
          self?.reload()
        } else {
          // Update the previously selected view.
          self?.selectedItem?.isHighlighted = false
          
          if let color = self?.view.background.color,
            let selectedItem = self?.selectedItem,
            let view = getWrapperView(for: selectedItem)
          {
            view.background.color = color
            view.forceRedraw()
            self?.selectedItem = nil
            selectedItem.isHighlighted = false
            selectedItem.itemView?.updateAppearance(style: Appearance.current)
            view.forceRedraw()
          }
          
          // Update the new selection
          if let item = treeViewItem {
            item.isHighlighted = true
            let wrapper = getWrapperView(for: item)
            wrapper?.background.color = .highlightedCellColor
            item.itemView?.updateAppearance(style: Appearance.current)
            self?.selectedItem = item
          }
        }
      }

      if treeViewItem.hasChildren {
        let expansionArrow = Button()
        expansionArrow.background.color = .clear
        if treeViewItem.isExpanded {
          let image = Image(filePath: resolveRelativeImagePath("Images/item-expanded-arrow.png"))
          expansionArrow.set(image: image,
                             forState: .unfocused)
        } else {
          let image = Image(filePath: resolveRelativeImagePath("Images/item-not-expanded-arrow.png"))
          expansionArrow.set(image: image,
                             forState: .unfocused)
        }
        itemIndentation += 5
        expansionArrow.width = 10~
        expansionArrow.height = 10~
        expansionArrow.imageView.width = 10~
        wrapperView.add(subview: expansionArrow)
      }

      wrapperView.set(padding: (itemIndentation + wrapperIndentation)~, for: .left)
      wrapperView.add(subview: itemView)
      wrapperView.width = 100%
      wrapperView.height = 20~
      
      itemView.width = 100%
      itemView.height = 100%
      treeView?.add(subview: wrapperView)
      
      itemView.set(margin: (itemIndentation)~, for: .left)
    }
    
    if treeViewItem.hasChildren && treeViewItem.isExpanded {
      if let children = treeViewItem.children {
        for child in children {
          add(from: child, level: level + 1)
        }
      }
    }
  }
  
  private func resolveRelativeImagePath(_ path: String) -> String {
    return URL(fileURLWithPath: #file + "/../../" + path)
      .standardizedFileURL.path
  }
  
  /// TreeViewDataSource
  
  open func getRootTreeViewItem() -> TreeViewItem? {
    return nil
  }
}
