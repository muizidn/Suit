//
// Created by pmacro on 14/01/17.
//

import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

///
/// The supported font types.
///
public enum FontType {
  case system
}

///
/// The supported font categories.
///
public enum FontCategory {
  case verySmall
  case small
  case smallMedium
  case medium
  case mediumLarge
  case large
  case larger
  case veryLarge
  case titleBarHeading
}

///
/// The supported font weights.
///
public enum FontWeight {
  case thin
  case ultraLight
  case light
  case medium
  case regular
  case bold
  case unknown
  
  #if os(macOS)
  var nsFontWeight: NSFont.Weight {
    switch self {
      case .thin:
        return .thin
      case .ultraLight:
        return .ultraLight
      case .light:
        return .light
      case .medium:
        return .medium
      case .bold:
        return .bold
      default:
        return .regular
    }
  }
  #endif
}

///
/// A platform independent representation of a font.
///
public struct Font {
  public var size: Double {
    didSet {
      platformFontHolder._platformFont = nil
    }
  }
  
  public var family: String {
    didSet {
      platformFontHolder._platformFont = nil
    }
  }
  public private (set) var isMonospaced = false
  
  public let weight: FontWeight
  
  class PlatformFontHolder {
    var _platformFont: Any?
  }
  
  private var type: FontType?
  
  private var platformFontHolder = PlatformFontHolder()
  
  private static var _systemFontName: String = {
    #if os(iOS)
    return UIFont.systemFont(ofSize: 10).fontName
    #elseif os(macOS)
    // Can't access the system font by name on macOS.
    return ""
    #else
    return "Ubuntu"
    #endif
  }()
    
  public init(size: Double, family: String) {
    self.size = size
    self.family = family
    self.weight = .unknown
    
    // Create the platform font and set any known properties on self.
    #if os(macOS)
    if let nsFont = platformFont as? NSFont {
      isMonospaced = nsFont.fontDescriptor.symbolicTraits.contains(.monoSpace)
    }
    #endif
  }
  
  public static func ofType(_ type: FontType,
                            category: FontCategory,
                            weight: FontWeight = .unknown) -> Font {
    let size: Double
    
    switch category {
      case .verySmall:
        #if os(iOS) || os(Android)
        size = 12
        #else
        size = 9
        #endif
      case .small:
        #if os(iOS) || os(Android)
        size = 14
        #else
        size = 10
        #endif
      case .smallMedium:
        #if os(iOS) || os(Android)
        size = 15
        #else
        size = 11
        #endif
      case .medium:
        #if os(iOS) || os(Android)
        size = 16
        #else
        size = 12
        #endif
      case .mediumLarge:
        #if os(iOS) || os(Android)
        size = 18
        #else
        size = 14
        #endif
      case .large:
        #if os(iOS) || os(Android)
        size = 20
        #else
        size = 16
        #endif
      case .larger:
        #if os(iOS) || os(Android)
        size = 25
        #else
        size = 18
        #endif
      case .veryLarge:
        #if os(iOS) || os(Android)
        size = 30
        #else
        size = 24
        #endif
      case .titleBarHeading:
        #if os(iOS) || os(Android)
        size = 22
        #else
        size = 14
        #endif
    }
    
    var font: Font
    
    #if os(macOS)
    // Special case for macOS where we can't access the system font by name.
    font = Font(size: size, family: "")
    font.platformFontHolder._platformFont = NSFont.systemFont(ofSize: CGFloat(size),
                                                              weight: weight.nsFontWeight)
    #else
    font = Font(size: size, family: Font._systemFontName)
    #endif
    
    font.type = type
    return font
  }
  
  public static func ofType(_ type: FontType, size: Double) -> Font {
    return Font(size: size, family: Font._systemFontName)
  }
}

extension Font {
  var platformFont: Any? {
    if platformFontHolder._platformFont == nil {
      #if os(macOS)
      if type == .system {
        platformFontHolder._platformFont = NSFont.systemFont(ofSize: CGFloat(size),
                                                             weight: weight.nsFontWeight)
      } else {
        platformFontHolder._platformFont = NSFont(name: family, size: CGFloat(size))
      }
      #elseif os(iOS)
      platformFontHolder._platformFont = UIFont(name: family, size: CGFloat(size))
      #else
      platformFontHolder._platformFont = nil
      #endif
    }
    return platformFontHolder._platformFont
  }
}
