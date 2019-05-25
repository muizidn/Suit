//
//  X11Clipboard.swift
//  Suit
//
//  Created by pmacro  on 13/03/2019.
//

#if os(Linux)
import Foundation
import CClipboard

public class X11Clipboard: PlatformClipboard {
  
  static let _general = X11Clipboard()
  let clipboard: OpaquePointer
  
  public init() {
    self.clipboard = clipboard_new(nil)
  }
  
  public func add(string: String) {
    string.utf8CString.withUnsafeBufferPointer { pointer in
      if let unbufferedPointer = pointer.baseAddress {
        clipboard_set_text(clipboard, unbufferedPointer)
      }
    }
  }
  
  public func peek() -> String? {
    if let stringPointer = clipboard_text(clipboard) {
      return String(cString: stringPointer)
    }
    
    return nil
  }
}

#endif
