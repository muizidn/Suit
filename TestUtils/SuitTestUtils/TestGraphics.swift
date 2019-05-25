//
//  TestGraphics.swift
//  SuitTestUtils
//
//  Created by pmacro  on 09/04/2019.
//

import Foundation
@testable import Suit

public class TestGraphics: Graphics {
  public var point: CGPoint = .zero
  
  public var lineWidth: Double = 0.0
  
  public func draw(rectangle: CGRect) {}
  
  public func draw(roundedRectangle: CGRect, cornerRadius radius: Double) {}
  
  public func clip(rectangle: CGRect) {}
  
  public func clip(roundedRectangle: CGRect, cornerRadius: Double) {}
  
  public func clip() {}
  
  public func fill() {}
  
  public func fill(rectangle: CGRect, usingImageMask image: Image, imageMode: ImageMode) {}
  
  public func stroke() {}
  
  public func flush() {}
  
  public func draw(imagePath: String, rectangle: CGRect, imageMode: ImageMode) {}
  
  public func draw(image: Image, rectangle: CGRect, imageMode: ImageMode) {}
  
  public func set(color: Color) {}
  
  public func set(font: Font) {}
  
  public func draw(text: String, inRect rectangle: CGRect, horizontalArrangement: HorizontalTextArrangement, verticalArrangement: VerticalTextArrangement, with lineAttributes: [TextAttribute]?, wrapping: TextWrapping) {}
  
  public func drawShadow(inRect rectange: CGRect) {}
  
  public func drawGradient(inRect rectangle: CGRect, startColor: Color, stopColor: Color) {}
  
  public func drawRadialGradient(inRect rectangle: CGRect, startColor: Color, stopColor: Color) {}
  
  public func size(of string: String, wrapping: TextWrapping) -> CGRect {
    return .zero
  }
  
  public func prepareForReuse() {}
  
}
