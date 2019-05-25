//
//  Image.swift
//  SuitPackageDescription
//
//  Created by pmacro on 24/05/2018.
//

import Foundation

#if os(macOS)
import AppKit
#endif

///
/// An image for use with an ImageView.
///
public class Image {
  
  ///
  /// The underlying storage for an image.
  ///
  enum StorageType {
    case path(path: String)
    #if os(macOS)
    case native(nsImage: NSImage)
    #endif
  }
  
  /// This image's storage type.
  internal let storageType: StorageType
  
  public init(filePath: String) {
    self.storageType = .path(path: filePath)
  }
  
  #if os(macOS)
  init(wrapping platformImage: NSImage) {
    self.storageType = .native(nsImage: platformImage)
  }
  #endif
}
