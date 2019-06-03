//
//  ContextMenuController.swift
//  Suit
//
//  Created by pmacro  on 12/03/2019.
//

import Foundation

///
///
///
public class ContextMenuController: ContextMenuSelectionDelegate {

  let menu: Menu
  var menuButton: Button?

  var currentMenu: MenuItem?

  let contentsComponent = ContextMenuComponent()

  init(menu: Menu) {
    self.menu = menu
  }

  func configureMenu(from point: CGPoint, asChildOf parent: Window?) {
    contentsComponent.delegate = self
    contentsComponent.itemHeight = 20

    let menuHeight: CGFloat = 200
    let menuWidth: CGFloat = 200

    let window = Window(rootComponent: contentsComponent,
                        frame: CGRect(x: point.x - (menuWidth / 2),
                                      y: point.y,
                                      width: menuWidth,
                                      height: menuHeight),
                        hasTitleBar: true)
    window.drawsSystemWindowButtons = false
    Application.shared.add(window: window, asChildOf: parent)
  }

  func display(menuItems: [MenuItem]) {
    contentsComponent.view.window.titleBarHeight =
      currentMenu?.parent == nil ? 0 : 45

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
      display(menuItems: menu.rootMenuItems)
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

protocol ContextMenuSelectionDelegate: class {
  func didSelect(menuItem: MenuItem)
  func goBack()
}
