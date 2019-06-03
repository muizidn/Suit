//
//  MacKeyEvent.swift
//  Suit
//
//  Created by pmacro on 19/06/2018.
//

#if os(macOS)

import Foundation
import AppKit

extension KeyModifiers {
  var asNSEventModifierFlag: NSEvent.ModifierFlags {
    switch self {
    case .capsLock:
      return .capsLock
    case .command:
      return .command
    case .control:
      return .control
    case .function:
      return .function
    case .help:
      return .help
    case .numericPad:
      return .numericPad
    case .option:
      return .option
    case .shift:
      return .shift
    }
  }
}

struct MacKeyEvent: KeyEvent {
  
  var strokeType: KeyStrokeType
  var keyType: KeyType
  var keyCode: UInt16
  var modifiers: [KeyModifiers]?
  
  var characters: String?
  
  init(event: NSEvent, isFlagsChangedEvent: Bool = false) {
    switch event.type {
    case .keyUp:
      strokeType = .up
    default:
      strokeType = .down
    }
        
    if !isFlagsChangedEvent,
      let code = event.characters?.first?.unicodeScalars.first?.value {
      switch Int(code) {
        case NSLeftArrowFunctionKey:
          keyType = .leftArrow
        case NSRightArrowFunctionKey:
          keyType = .rightArrow
        case NSUpArrowFunctionKey:
          keyType = .upArrow
        case NSDownArrowFunctionKey:
          keyType = .downArrow
        case NSDeleteCharacter, NSDeleteFunctionKey:
          keyType = .delete
        case NSEnterCharacter:
          keyType = .enter
        case NSCarriageReturnCharacter:
          keyType = .return
        default:
          keyType = .other
      }
    } else {
      keyType = .other
    }
    
    keyCode = event.keyCode
    characters = isFlagsChangedEvent ? nil : event.charactersIgnoringModifiers
    
    if !event.modifierFlags.isEmpty {
      modifiers = []
      
      if event.modifierFlags.contains(.capsLock) {
        modifiers?.append(.capsLock)
      }
      if event.modifierFlags.contains(.shift) {
        modifiers?.append(.shift)
      }
      if event.modifierFlags.contains(.control) {
        modifiers?.append(.control)
      }
      if event.modifierFlags.contains(.option) {
        modifiers?.append(.option)
      }
      if event.modifierFlags.contains(.command) {
        modifiers?.append(.command)
      }
      if event.modifierFlags.contains(.numericPad) {
        modifiers?.append(.numericPad)
      }
      if event.modifierFlags.contains(.help) {
        modifiers?.append(.help)
      }
      if event.modifierFlags.contains(.function) {
        modifiers?.append(.function)
      }
    }
  }
  
  public init(withCharacters characters: String?,
              strokeType: KeyStrokeType,
              modifiers: [KeyModifiers]?,
              keyType: KeyType) {
    self.characters = characters
    self.strokeType = strokeType
    self.modifiers = modifiers ?? []
    self.keyType = keyType
    self.keyCode = 0
  }

}
#endif
