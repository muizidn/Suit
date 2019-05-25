//
//  Clipboard.swift
//  Suit
//
//  Created by pmacro  on 13/03/2019.
//

import Foundation

public protocol PlatformClipboard {
  func add(string: String)
  func peek() -> String?
}

///
/// Clipboard provides a platform independant API for communicating with the system
/// clipboard.
///
public class Clipboard {
  /// The platform clipboard implementation.
  public static var general: PlatformClipboard {
    #if os(macOS)        
    return MacClipboard._general
    #elseif os(Linux)
    return X11Clipboard._general
    #else    
    fatalError("No clipboard is available on this platform.")
    #endif
  }
}
