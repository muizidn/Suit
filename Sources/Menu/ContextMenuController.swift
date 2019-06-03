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

  func apply(to window: Window) {
    guard let titleBar = window.titleBar else {
      print("Error: cannot apply a menu to a window that has no title bar.")
      return
    }

    #if os(Linux)
    let menuButton = titleBar.createMenuButton()
    self.menuButton = menuButton

    menuButton.onPress = { [weak self] in
      let point = menuButton.coordinatesInWindowSpace(from: menuButton.frame.origin)
      self?.configureMenu(from: CGPoint(x: point.x,
                                        y: menuButton.frame.height + point.y),
                          asChildOf: menuButton?.window)
      self?.displayRootMenu()
    }
    #endif
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

protocol ContextMenuSelectionDelegate: class {
  func didSelect(menuItem: MenuItem)
  func goBack()
}
