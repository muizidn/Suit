//
//  GtkStyleMenu.swift
//  Suit
//
//  Created by pmacro  on 12/03/2019.
//

import Foundation

///
///
///
public class GtkStyleMenu: GtkMenuSelectionDelegate {

  let menu: Menu
  var menuButton: Button?

  var currentMenu: MenuItem?

  let contentsComponent = GtkMenuContentsComponent()

  init(menu: Menu) {
    self.menu = menu
  }

  func apply(to window: Window) {
    guard let titleBar = window.titleBar else {
      print("Error: cannot apply a menu to a window that has no title bar.")
      return
    }

    #if os(Linux)
    let menuButton = titleBar.createMenuButton()
    self.menuButton = menuButton

    menuButton.onPress = { [weak self] in
      self?.configureMenu()
      self?.displayRootMenu()
    }
    #endif
  }

  func configureMenu() {
    contentsComponent.delegate = self
    contentsComponent.itemHeight = 20

    let menuHeight: CGFloat = 200
    let menuWidth: CGFloat = 200

    guard let menuButton = menuButton else { return }

    let point = menuButton.coordinatesInWindowSpace(from: menuButton.frame.origin)
    let position = CGPoint(x: point.x, y: menuButton.frame.height + point.y)

    let window = Window(rootComponent: contentsComponent,
                        frame: CGRect(x: position.x - (menuWidth / 2),
                                      y: position.y,
                                      width: menuWidth,
                                      height: menuHeight),
                        hasTitleBar: true)
    window.drawsSystemWindowButtons = false
    Application.shared.add(window: window, asChildOf: menuButton.window)
  }

  func displayRootMenu() {
    var rootItems = menu.rootMenuItems

    let applicationMenuIndex = rootItems
      .firstIndex(where: { $0.title.lowercased() == "application" })

    if let index = applicationMenuIndex {
      let applicationMenu = rootItems.remove(at: index)
      rootItems.append(contentsOf: applicationMenu.subMenuItems ?? [])
    }

    display(menuItems: rootItems)
  }

  func display(menuItems: [MenuItem]) {
    contentsComponent.items = menuItems
    contentsComponent.reload()
  }

  func didSelect(menuItem: MenuItem) {
    menuItem.action?()

    if let subItems = menuItem.subMenuItems, !subItems.isEmpty {
      display(menuItems: subItems)
    } else {
      contentsComponent.view.window.close()
    }
  }

  func goBack() {
    if let parent = currentMenu?.parent {
      didSelect(menuItem: parent)
    } else {
      displayRootMenu()
    }
  }

  func onKeyboardShortcutPress(_ keyPress: KeyEvent) {
    guard keyPress.strokeType == .down else { return }

    if keyPress.modifiers?.contains(.control) == true
      || keyPress.modifiers?.contains(.shift) == true, 
      let keyEquivalent = keyPress.characters 
    {
      menu.menuItem(for: keyEquivalent, modifiers: keyPress.modifiers)?.action?()
    }
  }
}

protocol GtkMenuSelectionDelegate: class {
  func didSelect(menuItem: MenuItem)
  func goBack()
}

class GtkMenuContentsComponent: ListComponent {

  var items: [MenuItem] = []
  weak var delegate: GtkMenuSelectionDelegate?
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
      guard let cell = cell as? GtkMenuItemCell else { return }
      cell.updateAppearance(style: Appearance.current)
    }

    listView?.onRemoveHighlight = { (indexPath, cell) in
      guard let cell = cell as? GtkMenuItemCell else { return }
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
    view.window.titleBarHeight = 45

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
    let cell = GtkMenuItemCell()
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

class GtkMenuItemCell: ListViewCell {
  let titleLabel = Label()
  let secondaryLabel = Label()

  override func didAttachToWindow() {
    super.didAttachToWindow()
    flexDirection = .row

    titleLabel.background.color = .clear
    titleLabel.set(margin: 10~, for: .left)
    titleLabel.verticalArrangement = .center
    titleLabel.height = 100%
    titleLabel.flex = 1
    add(subview: titleLabel)

    secondaryLabel.background.color = .clear
    secondaryLabel.set(margin: 10~, for: .right)
    secondaryLabel.verticalArrangement = .center
    secondaryLabel.horizontalArrangement = .right
    secondaryLabel.height = 100%
    secondaryLabel.width = 60~
    add(subview: secondaryLabel)

    updateAppearance(style: Appearance.current)
  }

  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    background.color = isHighlighted ? .highlightedCellColor : .backgroundColor
    titleLabel.textColor = isHighlighted ? .white : .textColor
    secondaryLabel.textColor = isHighlighted ? .white : .textColor
  }
}
