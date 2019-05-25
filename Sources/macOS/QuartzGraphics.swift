//
//  QuartzGraphics.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

import Foundation

#if os(macOS) || os(iOS)

import CoreGraphics

public class QuartzGraphics: Graphics {

  public var point: CGPoint = .zero
  public var lineWidth: Double = 1
  public var currentFont = Font.ofType(.system, category: .small)
  
  var currentColor: Color = .black
  
  let window: Window
  var coreGraphics: CGContext?
  
  init(window: Window) {
    self.window = window
  }
  
  public func draw(rectangle: CGRect) {
    let rect = translateRectangleToWindowCoordinates(rectangle)
    coreGraphics?.addRect(rect)
  }
  
  public func draw(roundedRectangle: CGRect, cornerRadius radius: Double) {

  }
  
  public func clip(rectangle: CGRect) {
    let rect = translateRectangleToWindowCoordinates(rectangle)
    coreGraphics?.clip(to: rect)
  }
  
  public func clip(roundedRectangle: CGRect, cornerRadius: Double) {
    fatalError("This method is expected to be implemented in a subclass.")
  }
  
  public func clip() {
    coreGraphics?.clip()
  }
  
  public func fill() {
    // No need to fill a clear color.
    if currentColor.alphaValue != 0 {
      coreGraphics?.fillPath()
    }
  }
  
  public func fill(rectangle: CGRect, usingImageMask image: Image, imageMode: ImageMode) {
    fatalError("This method is expected to be implemented in a subclass.")
  }
  
  public func stroke() {
    coreGraphics?.setLineWidth(CGFloat(lineWidth))
    coreGraphics?.strokePath()
  }
  
  public func flush() {
    coreGraphics?.restoreGState()
    coreGraphics?.synchronize()
    coreGraphics?.flush()
  }
  
  public func draw(text: String,
                   inRect rectangle: CGRect,
                   horizontalArrangement: HorizontalTextArrangement,
                   verticalArrangement: VerticalTextArrangement,
                   with lineAttributes: [TextAttribute]?,
                   wrapping: TextWrapping) {
    fatalError("This method is expected to be implemented in a subclass.")
  }
  
  public func size(of string: String, wrapping: TextWrapping) -> CGRect {
    let rect = CGRect(x: 0, y: 0, width: 9999, height: 9999)
    let path = CGMutablePath()
    path.addRect(rect)
    
    guard let platformFont = currentFont.platformFont else {
      fatalError("Unable to get underlying platform font for current font: \(currentFont.family)")
    }
    
    let stringAttributes = [NSAttributedString.Key.font : platformFont]
    let attrString = NSAttributedString(string: string, attributes: stringAttributes)
    let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
    
    let frame = CTFramesetterCreateFrame(framesetter,
                                         CFRangeMake(0, attrString.length),
                                         path,
                                         nil)
    
    let lines = CTFrameGetLines(frame) as NSArray
    
    if let line = lines.firstObject {
      let rect = CTLineGetBoundsWithOptions(line as! CTLine, [])
      return CGRect(x: 0,
                    y: 0,
                    width: rect.size.width + abs(rect.origin.x),
                    height: rect.size.height + abs(rect.origin.y))
    }
    
    return .zero
  }

  public func draw(imagePath: String, rectangle: CGRect, imageMode: ImageMode) {
    fatalError("This method is expected to be implemented in a subclass.")
  }
  
  public func draw(image: Image, rectangle: CGRect, imageMode: ImageMode) {
    fatalError("This method is expected to be implemented in a subclass.")
  }
  
  public func set(color: Color) {
    coreGraphics?.setFillColor(color.cgColor)
    coreGraphics?.setStrokeColor(color.cgColor)
    currentColor = color
  }
  
  public func set(font: Font) {
    if font.family != currentFont.family {
      if let cgFont = CGFont(font.family as CFString) {
        coreGraphics?.setFont(cgFont)
      }
    }
    
    coreGraphics?.setFontSize(CGFloat(font.size))
    currentFont = font
  }
  
  public func drawShadow(inRect rectange: CGRect) {
    fatalError("This method is expected to be implemented in a subclass.")
  }
  
  public func drawGradient(inRect rectangle: CGRect, startColor: Color, stopColor: Color) {
    let rect = translateRectangleToWindowCoordinates(rectangle)

    let colors = [startColor.cgColor, stopColor.cgColor]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colorLocations: [CGFloat] = [0.0, 1.0]
    
    let gradient = CGGradient(colorsSpace: colorSpace,
                              colors: colors as CFArray,
                              locations: colorLocations)!
    
    let startPoint = CGPoint(x: rect.origin.x + (rect.width / 2),
                             y: rect.origin.y)
    let endPoint = CGPoint(x: rect.origin.x + (rect.width / 2),
                           y: rect.origin.y + rect.height)
    
    coreGraphics?.drawLinearGradient(gradient,
                                     start: startPoint,
                                     end: endPoint,
                                     options: [])
  }
  
  public func drawRadialGradient(inRect rectangle: CGRect, startColor: Color, stopColor: Color) {
    fatalError("This method is expected to be implemented in a subclass.")
  }
  
  public func prepareForReuse() {
    coreGraphics?.saveGState()
  }
  
  func calculateRectangle(forImage imageRef: CGImage,
                          originalRectangle rectangle: CGRect,
                          imageMode: ImageMode) -> CGRect {
    var rect = translateRectangleToWindowCoordinates(rectangle)
    let horizontalScale: CGFloat
    let verticalScale: CGFloat
    let xPos: CGFloat
    let yPos: CGFloat
    
    switch imageMode {
    case .fill:
      horizontalScale = CGFloat(imageRef.width) / rect.width
      verticalScale = CGFloat(imageRef.height) / rect.height
      xPos = rect.origin.x
      yPos = rect.origin.y
    case .maintainAspectRatio:
      let horizontal = CGFloat(imageRef.width) / rect.width
      let vertical = CGFloat(imageRef.height) / rect.height
      horizontalScale = max(horizontal, vertical)
      verticalScale = horizontalScale
      
      let scaledImageWidth = CGFloat(imageRef.width) * (1 / horizontalScale)
      let scaledImageHeight = CGFloat(imageRef.height) * (1 / verticalScale)
      
      xPos = (rect.origin.x
        + ((rect.width - scaledImageWidth) / 2))
      
      yPos = (rect.origin.y
        + ((rect.height - scaledImageHeight) / 2))
    }
    
    rect.origin.x = xPos
    rect.origin.y = yPos
    rect.size.width = CGFloat(imageRef.width) * (1 / horizontalScale)
    rect.size.height = CGFloat(imageRef.height) * (1 / verticalScale)
    
    return rect
  }
}

#endif
