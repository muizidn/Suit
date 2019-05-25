//
//  iOSGraphics.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

#if os(iOS)

import Foundation

import UIKit

public class iOSGraphics: QuartzGraphics {
  
  let frameworkURL: URL
  
  override var coreGraphics: CGContext? {
    set {}
    get {
      let context = UIGraphicsGetCurrentContext()
//      if context == nil {
//        print("No graphics context...")
//      }
      return context
    }
  }
  
  public class func create(inWindow window: Window) -> Graphics {
    return iOSGraphics(window: window)
  }
  
  override init(window: Window) {
   frameworkURL =  Bundle(for: iOSGraphics.self).bundleURL
    super.init(window: window)
  }
  
  public override func draw(roundedRectangle: CGRect, cornerRadius radius: Double) {
    let frame = translateRectangleToWindowCoordinates(roundedRectangle)
    let path = UIBezierPath(roundedRect: frame,
                            cornerRadius: CGFloat(radius / 2)).cgPath
    coreGraphics?.addPath(path)
  }
  
  public override func clip(roundedRectangle: CGRect, cornerRadius: Double) {
    let frame = translateRectangleToWindowCoordinates(roundedRectangle)

    let path = UIBezierPath(roundedRect: frame,
                            cornerRadius: CGFloat(cornerRadius / 2)).cgPath
    coreGraphics?.addPath(path)
    coreGraphics?.clip()
  }

  override public func draw(text: String,
                            inRect rectangle: CGRect,
                            horizontalArrangement: HorizontalTextArrangement,
                            verticalArrangement: VerticalTextArrangement,
                            with lineAttributes: [TextAttribute]?) {
    let frame = translateRectangleToWindowCoordinates(rectangle)

    let string = text as NSString
    let stringAttributes = [NSAttributedStringKey.foregroundColor : currentColor.platformColor as Any,
                            NSAttributedStringKey.font : currentFont?.platformFont]

    var point: CGPoint = frame.origin
    let stringSize = string.size(withAttributes: stringAttributes)
    
    switch (verticalArrangement) {
    case .top:
      // 'point' starts with the correct value for 'top'.
      break
    case .center:
      point.y += ((frame.height - stringSize.height) / 2)
    case .bottom:
      point.y += frame.height - stringSize.height
    }
    
    switch (horizontalArrangement) {
    case .left:
      // 'point' starts with the correct value for 'left'.
      break
    case .center:
      point.x += (frame.width - stringSize.width) / 2
    case .right:
      point.x += frame.width - stringSize.width
    }
    
    string.draw(at: point,
                withAttributes: stringAttributes)
  }
  
  public override func draw(imagePath: String, rectangle: CGRect, imageMode: ImageMode) {
    let path = frameworkURL.appendingPathComponent(imagePath).path
    guard let imageRef = UIImage(contentsOfFile: path)?.cgImage else {
      print("Couldn't load image at path: \(path)")
      return
    }
    
    let frame = calculateRectangle(forImage: imageRef,
                                  originalRectangle: rectangle,
                                  imageMode: imageMode)
    
    coreGraphics?.draw(imageRef, in: frame)
  }
  
  public override func fill(rectangle: CGRect, usingImageMask imagePath: String, imageMode: ImageMode) {
    let path = frameworkURL.appendingPathComponent(imagePath).path
    guard let imageRef = UIImage(contentsOfFile: path)?.cgImage else {
      print("Couldn't load image at path: \(path)")
      return
    }
    
    let frame = calculateRectangle(forImage: imageRef,
                                  originalRectangle: rectangle,
                                  imageMode: imageMode)
    
    coreGraphics?.clip(to: frame, mask: imageRef)
    draw(rectangle: frame)
    fill()    
  }
}
#endif
