//
//  Cursor.swift
//  Suit
//
//  Created by pmacro on 19/06/2018.
//

import Foundation

public enum CursorType {
  case arrow  
  case iBeam
  case resizeLeftRight
  case resizeUpDown
}

public protocol CursorStack {
  func push(type: CursorType)
  func pop()
}

open class Cursor {
  public static var shared: Cursor = Cursor()
  public func push(type: CursorType) {}
  public func pop() {}
}
