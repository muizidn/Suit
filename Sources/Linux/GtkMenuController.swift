//
//  GtkMenyController.swift
//  Suit
//
//  Created by Paul MacRory on 03/06/2019.
//

import Foundation

#if os(Linux)
extension ContextMenuController {
  
  func createTitleBarMenu(in window: Window) {
    guard let titleBar = window.titleBar else {
      print("Error: cannot apply a menu to a window that has no title bar.")
      return
    }
    
    let menuButton = titleBar.createMenuButton()
    self.menuButton = menuButton
    
    menuButton.onPress = { [weak self] in
      let point = menuButton.coordinatesInWindowSpace(from: menuButton.frame.origin)
      self?.configureMenu(from: CGPoint(x: point.x,
                                        y: menuButton.frame.height + point.y),
                          asChildOf: menuButton.window)
      self?.displayRootMenu()
    }
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
}
#endif
