//
//  Color.swift
//  Suit
//
//  Created by pmacro  on 13/01/2017.
// 
//

import Foundation

public typealias Color = Colour

///
/// A colour, composed of red, green, blue, and alpha values.
///
public struct Colour: Equatable, Codable, ExpressibleByIntegerLiteral {
  public typealias IntegerLiteralType = Int

  public static func ==(lhs: Color, rhs: Color) -> Bool {
    return lhs.alphaValue == rhs.alphaValue
      && lhs.greenValue == rhs.greenValue
      && lhs.redValue == rhs.redValue
      && lhs.blueValue == rhs.blueValue
  }

  /// The red value (between 0 and 1) in this color.
  public var redValue: Double
  
  /// The green value (between 0 and 1) in this color.
  public var greenValue: Double
  
  /// The blue value (between 0 and 1) in this color.
  public var blueValue: Double
  
  /// The alpha value (between 0 and 1) in this color.
  public var alphaValue: Double

  public static let clear = Color(red: 0, green: 0, blue: 0, alpha: 0)
  public static let red = Color(red: 1, green: 0, blue: 0, alpha: 1)
  public static let green = Color(red: 0, green: 1, blue: 0, alpha: 1)
  public static let lightBlue = Color(red:0.20, green:0.79, blue:0.94, alpha:1.0)
  public static let lighterBlue = Color(red:0.909803, green:0.9490, blue:1, alpha:1.0)
  public static let mediumBlue = Color(red:0.00, green:0.69, blue:0.84, alpha:1.0)
  public static let blue = Color(red: 0, green: 0, blue: 1, alpha: 1)
  public static let darkBlue = Color(red:0.02, green:0.50, blue:0.61, alpha:1.0)
  public static let white = Color(red: 1, green: 1, blue: 1, alpha: 1)
  public static let black = Color(red: 0, green: 0, blue: 0, alpha: 1)
  public static let gray = Color(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
  public static let lightGray = Color(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
  public static let lighterGray = Color(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
  public static let darkGray = Color(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
  public static let darkerGray = Color(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
  public static let orange: Color = 0xE95420

  public static var darkTextColor = Color(red: 0.164, green: 0.164, blue: 0.164)
  public static var lightTextColor = Color(red: 0.95, green: 0.95, blue: 0.95)

  /// The default text color for the current appearance state.
  public static var textColor: Color {
    return Appearance.current == .light ? darkTextColor
                                        : lightTextColor
  }

  /// The text area background color for light appearances.
  public static var lightTextAreaBackgroundColor = Color(red: 1,
                                                         green: 1,
                                                         blue: 1)
  
  /// The text area background color for dark appearances.
  public static var darkTextAreaBackgroundColor = Color(red: 0.160,
                                                        green: 0.164,
                                                        blue: 0.184)

  /// The default text area background color for the current appearance state.
  public static var textAreaBackgroundColor: Color {
    return Appearance.current == .light ? lightTextAreaBackgroundColor
                                        : darkTextAreaBackgroundColor
  }

  /// The default highligted cell color for the light appearance state.
  public static var lightHighlightedCellColor: Color = 0x0F65FE
  
  /// The default highligted cell color for the dark appearance state.
  public static var darkHighlightedCellColor: Color = 0x0F65FE

  /// The default highligted cell color for the current appearance state.
  public static var highlightedCellColor: Color {
    #if os(Linux)
    return 0xE95420
    #else
    return Appearance.current == .light ? lightHighlightedCellColor
                                        : darkHighlightedCellColor
    #endif
  }

  /// The default background color for the current appearance state.
  public static var backgroundColor: Color {
    return Appearance.current == .light ? lighterGray
                                        : darkerGray
  }

  /// The default text selection color for the current appearance state.
  public static var textSelectionColor = Color(red: 184/255,                                                                         green: 215/255,
                                               blue: 251/255)

  public static var lightScrollBarColor = Color(red: 0.25,
                                           green: 0.25,
                                           blue: 0.25,
                                           alpha: 0.7)

  public static var darkScrollBarColor = Color(red: 0.75,
                                               green: 0.75,
                                               blue: 0.75,
                                               alpha: 0.3)

  public static var scrollBarColor: Color {
    return Appearance.current == .light ? lightScrollBarColor : darkScrollBarColor
  }

  public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
    self.redValue = red
    self.greenValue = green
    self.blueValue = blue
    self.alphaValue = alpha
  }

  public init(integerLiteral value: Int) {
    self.init(rgb: value)
  }

  public init(rgb: Int) {
    self.init(
      red: Double((rgb >> 16) & 0xFF) / 255,
      green: Double((rgb >> 8) & 0xFF) / 255,
      blue: Double(rgb & 0xFF) / 255
    )
  }

  public func lighter() -> Color {
    var color = self
    color.redValue = min(1, color.redValue + 0.1)
    color.greenValue = min(1, color.greenValue + 0.1)
    color.blueValue = min(1, color.blueValue + 0.1)
    return color
  }

  public func darker() -> Color {
    var color = self
    color.redValue = max(0, color.redValue - 0.1)
    color.greenValue = max(0, color.greenValue - 0.1)
    color.blueValue = max(0, color.blueValue - 0.1)
    return color
  }

  ///
  /// Inverts this color.  This method does not affect the alpha value.
  ///
  mutating public func invert() {
    redValue = 1 - redValue
    greenValue = 1 - greenValue
    blueValue = 1 - blueValue
  }

  public func inverted() -> Color {
    var inverted = self
    inverted.invert()
    return inverted
  }
}

#if os(macOS)
import AppKit

extension Color {
  var platformColor: NSColor {
    return NSColor(calibratedRed: CGFloat(redValue),
                   green: CGFloat(greenValue),
                   blue: CGFloat(blueValue),
                   alpha: CGFloat(alphaValue))
  }

  var cgColor: CGColor {
    return CGColor(red: CGFloat(redValue), green: CGFloat(greenValue), blue: CGFloat(blueValue), alpha: CGFloat(alphaValue))
  }
}

#endif

#if os(iOS)
import UIKit

extension Color {
  var platformColor: UIColor {
    return UIColor(red: CGFloat(redValue),
                   green: CGFloat(greenValue),
                   blue: CGFloat(blueValue),
                   alpha: CGFloat(alphaValue))
  }

  var cgColor: CGColor {
    return platformColor.cgColor
  }
}

#endif

