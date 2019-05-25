//
//  Graphics.swift
//  Suit
//
//  Created by pmacro  on 17/05/2018.
//

import Foundation

#if os(Linux)
import Cairo
import Pango
#endif

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

///
/// Text wrapping options.
///
public enum TextWrapping {
  case none
  case word
  case character
}

///
/// A platform independent API for drawing.  Each platform that supports Suit has its own
/// concrete implementation conforming to this protocol.
///
public protocol Graphics {
  /// The point to draw relative to.
  var point: CGPoint { get set }
  var lineWidth: Double { get set }

  func draw(rectangle: CGRect)
  func draw(roundedRectangle: CGRect, cornerRadius radius: Double)
  func clip(rectangle: CGRect)
  func clip(roundedRectangle: CGRect, cornerRadius: Double)
  func clip()
  func fill()
  func fill(rectangle: CGRect, usingImageMask image: Image, imageMode: ImageMode)
  func stroke()
  func flush()
  func draw(imagePath: String, rectangle: CGRect, imageMode: ImageMode)
  func draw(image: Image, rectangle: CGRect, imageMode: ImageMode)
  func set(color: Color)
  func set(font: Font)
  func draw(text: String,
            inRect rectangle: CGRect,
            horizontalArrangement: HorizontalTextArrangement,
            verticalArrangement: VerticalTextArrangement,
            with lineAttributes: [TextAttribute]?,
            wrapping: TextWrapping)
  func drawShadow(inRect rectange: CGRect)
  func drawGradient(inRect rectangle: CGRect,
                    startColor: Color,
                    stopColor: Color)
  func drawRadialGradient(inRect rectangle: CGRect,
                          startColor: Color,
                          stopColor: Color)
  func size(of string: String, wrapping: TextWrapping) -> CGRect
  func prepareForReuse()
  func translateRectangleToWindowCoordinates(_ rectangle: CGRect) -> CGRect
  }

///
/// A factory for creating a Graphics instance for the current platform.
///
class PlatformGraphics {
  
  ///
  /// Populates `window.graphics` with a graphics implementation suitable
  /// for the current platform.
  ///
  static func create(inWindow window: Window) {
#if os(Linux)
    window.graphics = CairoGraphics.createForX11(inWindow: window)
    return
#elseif os(macOS)
    window.graphics = MacGraphics.create(inWindow: window)
    return
#elseif os(iOS)
    window.graphics = iOSGraphics.create(inWindow: window)
    return
#else
    fatalError("Suit is not supported on this platform.")
#endif
  }
}

extension Graphics {
  ///
  /// Translates a `rectangle` in its local coordindate system to the window's coordinate
  /// system.
  ///
  public func translateRectangleToWindowCoordinates(_ rectangle: CGRect) -> CGRect {
    var rect = rectangle
    rect.origin.x += point.x
    rect.origin.y += point.y
    return rect
  }
}
