//
//  Dropdown.swift
//  Suit
//
//  Created by pmacro  on 08/03/2019.
//

import Foundation

///
/// A dropdown box.  Use the `items` property to provide the contents and the
/// onSelect callback to be notified of selections.
///
open class Dropdown: View, DropdownSelectionDelegate {
  /// The label that displays the currently selected value.
  let currentValueLabel: Label
  
  /// The height of each item in the dropdown list.
  public var itemHeight: CGFloat = 20
  
  public required init() {
    currentValueLabel = Label()

    super.init()
    
    background.borderSize = 0.4
    background.cornerRadius = 8
    
    currentValueLabel.background.color = .clear
    currentValueLabel.set(margin: 5~, for: .left)
    currentValueLabel.verticalArrangement = .center
    add(subview: currentValueLabel)
  }
  
  ///
  /// The items to be displayed for selection in the dropdown.
  ///
  open var items: [String] = [] {
    didSet {
      updateCurrentValueLabel()
    }
  }
  
  /// The index of the currently selected item.
  open var selectedItemIndex = 0 {
    didSet {
      updateCurrentValueLabel()
    }
  }
  
  /// Callback invoked whenever an item is selected.
  open var onSelect: ((_ selectedIndex: Int) -> Void)?
  
  open override func didAttachToWindow() {
    super.didAttachToWindow()
    updateCurrentValueLabel()
  }
  
  ///
  /// Called whenever the user selects something in the popover list.
  ///
  func didSelect(item: Int) {
    selectedItemIndex = item
    onSelect?(selectedItemIndex)
  }
  
  ///
  /// Updates the label with the value corresponding to the current selection.
  ///
  func updateCurrentValueLabel() {
    if selectedItemIndex >= 0 && selectedItemIndex < items.count {
      currentValueLabel.text = items[selectedItemIndex]
    } else {
      currentValueLabel.text = nil
    }
  }
  
  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    switch pointerEvent.type {
      case .click:
        showDropdown()
        return true
      default:
        return false
    }
  }
  
  ///
  /// Draw the dropdown.
  ///
  public override func draw(rect: CGRect) {
    super.draw(rect: rect)
    let indicatorSize: CGFloat = 17.5
    
    var circleRect = rect
    circleRect.size.width = indicatorSize
    circleRect.origin.x = rect.origin.x + rect.width - indicatorSize
    
    graphics.lineWidth = 0
    graphics.set(color: .highlightedCellColor)
    graphics.draw(roundedRectangle: circleRect,
                  cornerRadius: 1)
    graphics.fill()
  }
  
  open override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    
    switch style {
    case .dark:
      background.color = .darkGray
      background.borderColor = .black
    case .light:
      background.color = .white
      background.borderColor = .darkerGray
    }
  }
  
  ///
  /// Shows a popup containing a list of dropdown options.
  ///
  func showDropdown() {
    let point = coordinatesInWindowSpace(from: frame.origin)
    let contentsComponent = DropdownContentsComponent(items: items)
    contentsComponent.delegate = self
    contentsComponent.itemHeight = itemHeight
    
    let window = Window(rootComponent: contentsComponent,
                                frame: CGRect(x: point.x,
                                              y: point.y,
                                          width: frame.width,
                                         height: itemHeight * CGFloat(items.count)),
                          hasTitleBar: false)
    
    Application.shared.add(window: window, asChildOf: self.window)
    contentsComponent.reload()
  }
}

protocol DropdownSelectionDelegate: class {
  func didSelect(item: Int)
}

///
/// A list component that displays a list of dropdown options.
///
class DropdownContentsComponent: ListComponent {
  
  let items: [String]
  weak var delegate: DropdownSelectionDelegate?
  var itemHeight: CGFloat = 20
  
  init(items: [String]) {
    self.items = items
    super.init()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.background.color = .lighterGray
    listView?.highlightingBehaviour = .single
    listView?.isSelectable = true
    listView?.selectsOnSinglePress = true
    listView?.highlightsOnRollover = true
    
    listView?.onHighlight = { (indexPath, cell) in
      guard let cell = cell as? DropdownItemCell else { return }
      cell.applyStyling(isHighlighted: true)
    }

    listView?.onRemoveHighlight = { (indexPath, cell) in
      guard let cell = cell as? DropdownItemCell else { return }
      cell.applyStyling(isHighlighted: false)
    }
    
    listView?.onSelection = { [weak self] (indexPath, cell) in
      self?.view.window.close()
      self?.delegate?.didSelect(item: indexPath.item)
    }
  }
  
  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    view.background.color = .backgroundColor
  }
  
  override func numberOfSections() -> Int {
    return 1
  }
  
  override func numberOfItemsInSection(section: Int) -> Int {
    return items.count
  }
  
  override func cellForItem(at indexPath: IndexPath, withState state: ListItemState) -> ListViewCell {
    let cell = DropdownItemCell()
    cell.label.text = items[indexPath.item]
    cell.width = 100%
    cell.applyStyling(isHighlighted: state.isHighlighted)
    return cell
  }
  
  override func heightOfCell(at indexPath: IndexPath) -> CGFloat {
    return 20
  }
}

class DropdownItemCell: ListViewCell {
  let label = Label()
  
  override func didAttachToWindow() {
    super.didAttachToWindow()
   
    label.background.color = .clear
    label.set(margin: 5~, for: .left)
    label.verticalArrangement = .center
    label.height = 100%
    applyStyling(isHighlighted: false)
    add(subview: label)
  }
  
  func applyStyling(isHighlighted: Bool) {
    background.color = isHighlighted ? .highlightedCellColor : .lighterGray
    label.textColor = isHighlighted ? .white : .black
  }
}
