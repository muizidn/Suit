//
//  KeyEvent.swift
//  Suit
//
//  Created by pmacro on 18/06/2018.
//

import Foundation

public enum KeyStrokeType {
  case down
  case up
}

public struct FunctionKeyCharacters {
  public static let upArrow: Character            = "\u{F700}"
  public static let downArrow: Character          = "\u{F701}"
  public static let leftArrow: Character          = "\u{F702}"
  public static let rightArrow: Character         = "\u{F703}"
}

public enum KeyType {
  case leftArrow
  case rightArrow
  case upArrow
  case downArrow
  case delete
  case enter
  case `return`
  case other

  public var isTextInput: Bool {
    return self == .other || self == .return || self == .enter
  }
}

public enum KeyModifiers {
  case capsLock
  case shift
  case control
  case option
  case command
  case numericPad
  case help
  case function
}

public protocol KeyEvent {
  var strokeType: KeyStrokeType { get }
  var keyType: KeyType { get }
  var characters: String? { get }
  var modifiers: [KeyModifiers]? { get }

  init(withCharacters characters: String?,
       strokeType: KeyStrokeType,
       modifiers: [KeyModifiers]?,
       keyType: KeyType)
}

public func createPlatformKeyEvent(characters: String,
                                   strokeType: KeyStrokeType,
                                   modifiers: [KeyModifiers]?,
                                   keyType: KeyType) -> KeyEvent {
  #if os(Linux)
  return LinuxKeyEvent(withCharacters: characters,
                       strokeType: strokeType,
                       modifiers: modifiers,
                       keyType: keyType)
  #elseif os(macOS)
  return MacKeyEvent(withCharacters: characters,
                     strokeType: strokeType,
                     modifiers: modifiers,
                     keyType: keyType)
  #else
  fatalError("Unsupported platform.")
  #endif
}
