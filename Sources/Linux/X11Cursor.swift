//
//  MacCursor.swift
//  Suit
//
//  Created by pmacro on 03/06/2019.
//

#if os(Linux)

import Foundation
import X11

///
/// A cursor stack for X11.
///
open class X11Cursor: Cursor {
  
  ///
  /// Push a new cursor onto the stack.
  ///
  public override func push(type: CursorType) {
    
    let cursor: UInt32

    switch type {
      case .iBeam:
        cursor = 152
      case .resizeLeftRight:
        cursor = 108
      case .resizeUpDown:
        cursor = 42
      default:
      // Arrow
      cursor = 2
    }

    let app = Application.shared as! X11Application
    let c = XCreateFontCursor(app.display, cursor)
    XDefineCursor (app.display, app.mainWindow.x11Window.realX11Window, c)
  }
  
  ///
  /// Pop the current cursor off the stack.
  ///
  public override func pop() {
    let app = Application.shared as! X11Application
    XUndefineCursor(app.display, app.mainWindow.x11Window.realX11Window)
  }
}

#endif
