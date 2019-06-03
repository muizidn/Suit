//
//  Menu.swift
//  Suit
//
//  Created by pmacro  on 08/03/2019.
//

import Foundation

public class Menu {
  var rootMenuItems: [MenuItem] = []
  
  public init(){}
  
  public func add(item: MenuItem) {
    rootMenuItems.append(item)
  }
  
  public func item(named title: String) -> MenuItem? {
    return rootMenuItems.first { $0.title == title }
  }
  
  func action(for id: Int) -> MenuItemAction? {
    for item in rootMenuItems {
      if let action = item.action(for: id) {
        return action
      }
    }
    
    return nil
  }
  
  func menuItem(for keyEquivalent: String, modifiers: [KeyModifiers]?) -> MenuItem? {
    for item in rootMenuItems {
      if let match = item.menuItem(for: keyEquivalent, modifiers: modifiers) {
        return match
      }
    }
    
    return nil
  }
}

public typealias MenuItemAction = () -> Void
public typealias MenuItemEnablementCheck = (MenuItem) -> Bool

public class MenuItem {
  public var title: String
  public var keyEquivalent: String?
  public var keyEquivalentModifiers: [KeyModifiers]
  public var subMenuItems: [MenuItem]?
  public var action: MenuItemAction?
  weak var parent: MenuItem?
  public var enablementCheck: MenuItemEnablementCheck?
  fileprivate static var counter = 0
  
  let uniqueIdentifier: Int
  
  public init(title: String,
              keyEquivalent: String? = nil,
              keyEquivalentModifiers: [KeyModifiers]? = nil,
              isEnabled: MenuItemEnablementCheck? = nil,
              action: MenuItemAction? = nil) {
    self.title = title
    self.keyEquivalent = keyEquivalent
    self.keyEquivalentModifiers = keyEquivalentModifiers ?? []

    #if os(macOS) || os(iOS)
    if !self.keyEquivalentModifiers.contains(.command) {
      self.keyEquivalentModifiers.append(.command)
    }
    #else
    if !self.keyEquivalentModifiers.contains(.control) {
      self.keyEquivalentModifiers.append(.control)
    }
    #endif

    self.action = action
    MenuItem.counter += 1
    self.uniqueIdentifier = MenuItem.counter
    self.enablementCheck = isEnabled
  }
  
  public func add(subItem: MenuItem) {
    if subMenuItems == nil { subMenuItems = [] }
    subMenuItems?.append(subItem)
    subItem.parent = self
  }
  
  func action(for id: Int) -> MenuItemAction? {
    if uniqueIdentifier == id { return action }
    guard let subMenuItems = subMenuItems else { return nil }
    
    for item in subMenuItems {
      if let action = item.action(for: id) {
        return action
      }
    }
    return nil
  }
  
  func menuItem(for keyEquivalent: String, modifiers: [KeyModifiers]?) -> MenuItem? {
    if self.keyEquivalent == keyEquivalent, 
       self.keyEquivalentModifiers == modifiers 
    {
      return self
    }
    
    guard let subMenuItems = subMenuItems else { return nil }

    for item in subMenuItems {
      if let match = item.menuItem(for: keyEquivalent, modifiers: modifiers) {
        return match
      }
    }
    
    return nil
  }
}
