//
//  ContextMenuComponent.swift
//  Suit
//
//  Created by pmacro on 03/06/2019.
//

import Foundation

class ContextMenuComponent: ListComponent {
  
  var items: [MenuItem] = []
  weak var delegate: ContextMenuSelectionDelegate?
  var itemHeight: CGFloat = 20
  
  let backButton = Button(ofType: .rounded)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureHeader()
    
    view.background.color = .lighterGray
    listView?.highlightingBehaviour = .single
    listView?.isSelectable = true
    listView?.selectsOnSinglePress = true
    listView?.highlightsOnRollover = true
    
    listView?.onHighlight = { (indexPath, cell) in
      guard let cell = cell as? ContextMenuItemCell else { return }
      cell.updateAppearance(style: Appearance.current)
    }
    
    listView?.onRemoveHighlight = { (indexPath, cell) in
      guard let cell = cell as? ContextMenuItemCell else { return }
      cell.updateAppearance(style: Appearance.current)
    }
    
    listView?.onSelection = { [weak self] (indexPath, cell) in
      if let items = self?.items {
        self?.delegate?.didSelect(menuItem: items[indexPath.item])
      }
    }
  }
  
  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    view.background.color = .backgroundColor
  }
  
  func configureHeader() {
    view.window.titleBar?.background.color = .backgroundColor
    
    view.window.titleBar?.additionalContentView.add(subview: backButton)
    backButton.set(margin: 10~, for: .top)
    backButton.set(margin: 10~, for: .bottom)
    backButton.set(margin: 10~, for: .left)
    backButton.set(margin: 10~, for: .right)
    backButton.width = 20~
    backButton.height = 20~
    
    if let backImagePath = Bundle.main.path(forAsset: "back", ofType: "png") {
      let image = Image(filePath: backImagePath)
      backButton.set(image: image)
      backButton.alignContent = .center
      backButton.justifyContent = .center
    }
    
    backButton.titleLabel.horizontalArrangement = .left
    backButton.onPress = { [weak self] in
      self?.delegate?.goBack()
    }
  }
  
  override func reload() {
    super.reload()
  }
  
  override func numberOfSections() -> Int {
    return 1
  }
  
  override func numberOfItemsInSection(section: Int) -> Int {
    return items.count
  }
  
  override func cellForItem(at indexPath: IndexPath, withState state: ListItemState) -> ListViewCell {
    let cell = ContextMenuItemCell()
    let menuItem = items[indexPath.item]
    cell.titleLabel.text = menuItem.title
    
    if menuItem.subMenuItems?.isEmpty == false {
      cell.secondaryLabel.text = "➤"
    } else if let keyEquivalent = menuItem.keyEquivalent  {
      cell.secondaryLabel.text = "Ctrl " + keyEquivalent.uppercased()
    }
    
    cell.width = 100%
    return cell
  }
  
  override func heightOfCell(at indexPath: IndexPath) -> CGFloat {
    return 20
  }
}
