//
//  TestKeyEvent.swift
//  Suit
//
//  Created by pmacro  on 07/02/2019.
//

import Foundation
import Suit

public struct TestKeyEvent: KeyEvent {
  public init(withCharacters characters: String?,
       strokeType: KeyStrokeType,
       modifiers: [KeyModifiers]?,
       keyType: KeyType) {
    self.characters = characters
    self.strokeType = strokeType
    self.modifiers = modifiers ?? []
    self.keyType = keyType
  }
  
  public var strokeType: KeyStrokeType
  
  public var keyType: KeyType
  
  public var characters: String?
  
  public var modifiers: [KeyModifiers]?
}

public let downKey = TestKeyEvent(withCharacters: nil,
                                  strokeType: .down,
                                  modifiers: nil,
                                  keyType: .downArrow)

public let leftKey = TestKeyEvent(withCharacters: nil,
                                  strokeType: .down,
                                  modifiers: nil,
                                  keyType: .leftArrow)

public let rightKey = TestKeyEvent(withCharacters: nil,
                                   strokeType: .down,
                                   modifiers: nil,
                                   keyType: .rightArrow)

public let upKey = TestKeyEvent(withCharacters: nil,
                                strokeType: .down,
                                modifiers: nil,
                                keyType: .upArrow)

public let deleteKey = TestKeyEvent(withCharacters: nil,
                                    strokeType: .down,
                                    modifiers: nil,
                                    keyType: .delete)

public let fullStopKey = TestKeyEvent(withCharacters: ".",
                                      strokeType: .down,
                                      modifiers: nil,
                                      keyType: .other)

public let newLineKey = TestKeyEvent(withCharacters: "\n",
                                     strokeType: .down,
                                     modifiers: nil,
                                     keyType: .other)

public var characterKey: (Character) -> TestKeyEvent = { character in
  return TestKeyEvent(withCharacters: "\(character)",
                      strokeType: .down,
                      modifiers: nil,
                      keyType: .other)
}
