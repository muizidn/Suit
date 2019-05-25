//
//  MacCursor.swift
//  Suit
//
//  Created by pmacro on 19/06/2018.
//

#if os(macOS)

import Foundation
import AppKit

open class MacCursor: Cursor {
  
  public override func push(type: CursorType) {
    let cursor: NSCursor
    
    switch type {
      case .iBeam:
        cursor = .iBeam
      case .resizeLeftRight:
        cursor = .resizeLeftRight
      case .resizeUpDown:
        cursor = .resizeUpDown
      default:
      cursor = .arrow
    }
    
    cursor.push()
  }
  
  public override func pop() {
    NSCursor.pop()
  }
}

#endif
