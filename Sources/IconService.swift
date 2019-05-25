//
//  IconService.swift
//  Suit
//
//  Created by pmacro  on 03/04/2019.
//

import Foundation

#if os(macOS)
import AppKit
#endif

///
/// A service that looks up icon images.
///
public class IconService {

#if os(Linux)
  static let linuxIconService = LinuxIconService()
#endif  

  ///
  /// Retrieves the icon image for the file in the provided path.  If it hasn't been
  /// possibe to locate an icon image for the file path, this method returns nil.
  ///
  /// - parameter path: the path to the file to retrieve an icon for.
  ///
  /// - returns: an image or nil.
  ///
  public static func icon(forFile path: String) -> Image? {
  #if os(macOS)
    return Image(wrapping: NSWorkspace.shared.icon(forFile: path))
  #elseif os(Linux)
    return linuxIconService.icon(forFile: path)
  #else
    return nil
  #endif
  }
}
