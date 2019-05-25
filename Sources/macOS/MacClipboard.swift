//
//  MacClipboard.swift
//  Suit
//
//  Created by pmacro  on 13/03/2019.
//

#if os(macOS)
import Foundation
import AppKit

public class MacClipboard: PlatformClipboard {
  
  let pasteboard: NSPasteboard
  
  static let _general = MacClipboard()
  
  public init() {
    self.pasteboard = NSPasteboard.general
    pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
  }
  
  public func add(string: String) {
    pasteboard.setString(string, forType: NSPasteboard.PasteboardType.string)
  }
  
  public func peek() -> String? {
    if let stringData = pasteboard.data(forType: .string) {
      return String(data: stringData, encoding: .utf8)
    }
    return nil
  }
}

#endif
