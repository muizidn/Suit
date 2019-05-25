//
//  MacGraphics.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

import Foundation

#if os(macOS)
import AppKit

public class MacGraphics: QuartzGraphics {
  
  public class func create(inWindow window: Window) -> Graphics {
    let graphics = MacGraphics(window: window)

    graphics.coreGraphics = NSGraphicsContext.current?.cgContext
    graphics.coreGraphics?.setShouldAntialias(true)
    
    return graphics
  }
  
  override init(window: Window) {
    super.init(window: window)
  }
  
  public override func draw(roundedRectangle: CGRect, cornerRadius radius: Double) {
    var rect = translateRectangleToWindowCoordinates(roundedRectangle)
    
    // https://stackoverflow.com/questions/5722085/nsbezierpath-rounded-rectangle-has-bad-corners
    rect = NSInsetRect(rect, 0.5, 0.5)
    
    let path = NSBezierPath(roundedRect: rect,
                            xRadius: CGFloat(radius) / 2,
                            yRadius: CGFloat(radius) / 2).cgPath
    coreGraphics?.addPath(path)
  }
  
  public override func clip(roundedRectangle: CGRect, cornerRadius: Double) {
    var rect = translateRectangleToWindowCoordinates(roundedRectangle)
    rect = NSInsetRect(rect, 0.5, 0.5)

    let path = NSBezierPath(roundedRect: rect,
                            xRadius: CGFloat(cornerRadius) / 2,
                            yRadius: CGFloat(cornerRadius) / 2).cgPath
    coreGraphics?.addPath(path)
    coreGraphics?.clip()
  }
  
  public override func fill(rectangle: CGRect, usingImageMask image: Image, imageMode: ImageMode) {

    let nsImage: NSImage?
    
    switch image.storageType {
      case .path(let imagePath):
        nsImage = NSImage(contentsOfFile: imagePath)
      case .native(let img):
        nsImage = img
    }
    
    guard let nsImg = nsImage,
          let imageRef = nsImg.cgImage(forProposedRect: nil,
                                       context: nil,
                                       hints: nil) else {
      print("Unable to create image: \(image)")
      return
    }
    
    var rect = calculateRectangle(forImage: imageRef,
                                  originalRectangle: rectangle,
                                  imageMode: imageMode)
    
    rect.origin.y = window.rootView.frame.height - (rect.origin.y + rect.height)
    
    coreGraphics?.saveGState()
    
    coreGraphics?.translateBy(x: 0, y: window.rootView.frame.height)
    coreGraphics?.scaleBy(x: 1, y: -1)
    
    coreGraphics?.clip(to: rect, mask: imageRef)
    
    let drawRect = rect.insetBy(dx: -rect.width / 2, dy: -rect.height / 2)
    draw(rectangle: drawRect)
    fill()
    coreGraphics?.restoreGState()
  }
    
  public override func draw(imagePath: String, rectangle: CGRect, imageMode: ImageMode) {
    guard let image = NSImage(contentsOfFile: imagePath) else {
        print("Unable to create image from path: \(imagePath)")
        return
    }
    
    draw(nsImage: image, rectangle: rectangle, imageMode: imageMode)
  }
  
  public override func draw(image: Image, rectangle: CGRect, imageMode: ImageMode) {
    switch image.storageType {
    case .path(let path):
      draw(imagePath: path, rectangle: rectangle, imageMode: imageMode)
    case .native(let nsImage):
      draw(nsImage: nsImage, rectangle: rectangle, imageMode: imageMode)
    }
  }

  private func draw(nsImage: NSImage, rectangle: CGRect, imageMode: ImageMode) {
    guard let imageRef = nsImage.cgImage(forProposedRect: nil,
                                         context: nil,
                                         hints: nil) else {
      print("Unable to create image: \(nsImage)")
      return
    }
    
    var rect = calculateRectangle(forImage: imageRef,
                                  originalRectangle: rectangle,
                                  imageMode: imageMode)
    
    rect.origin.y = window.rootView.frame.height - (rect.origin.y + rect.height)
    
    coreGraphics?.saveGState()
    
    coreGraphics?.translateBy(x: 0, y: window.rootView.frame.height)
    coreGraphics?.scaleBy(x: 1, y: -1)
    
    coreGraphics?.draw(imageRef, in: rect)
    coreGraphics?.restoreGState()

  }
  
  public override func draw(text: String,
                            inRect rectangle: CGRect,
                            horizontalArrangement: HorizontalTextArrangement,
                            verticalArrangement: VerticalTextArrangement,
                            with lineAttributes: [TextAttribute]?,
                            wrapping: TextWrapping) {
    var rect = translateRectangleToWindowCoordinates(rectangle)

    let string = text as NSString
    let stringAttributes: [NSAttributedString.Key: Any]
      = [NSAttributedString.Key.foregroundColor : currentColor.platformColor as Any,
         NSAttributedString.Key.font : currentFont.platformFont as Any]
    
    var point: CGPoint = rect.origin
    point.y = window.rootView.frame.height - (rect.origin.y + rect.height)
    
    // String.size is expensive, so let's skip it when it's not needed.
    //
    if !(verticalArrangement == .top && horizontalArrangement == .left) {
      let stringSize = string.size(withAttributes: stringAttributes)
    
      switch (verticalArrangement) {
        case .top:
          // 'point' starts with the correct value for 'top'.
          break
        case .center:
          point.y -= ((rect.height - stringSize.height) / 2)
        case .bottom:
          point.y -= rect.height - stringSize.height
        }
      
      switch (horizontalArrangement) {
        case .left:
          // 'point' starts with the correct value for 'left'.
          break
        case .center:
          point.x += (rect.width - stringSize.width) / 2
        case .right:
          point.x += rect.width - stringSize.width
      }
    }
    
    coreGraphics?.saveGState()
    
    coreGraphics?.translateBy(x: 0, y: window.rootView.frame.height)
    coreGraphics?.scaleBy(x: 1, y: -1)

    let attrString = NSMutableAttributedString(string: text,
                                               attributes: stringAttributes)
    let stringCount = attrString.length
    
    if let lineAttributes = lineAttributes {
      for attribute in lineAttributes {
        if let range = attribute.createUTF16Range(using: text),
          range.upperBound <= stringCount && range.length > 0
        {
          attrString.addAttributes(
            [NSAttributedString.Key.foregroundColor : attribute.color.platformColor],
            range: range)
        }
      }
    }
    
    let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
    rect.origin = point
    let path = CGMutablePath()
    path.addRect(rect)

    let frame = CTFramesetterCreateFrame(framesetter,
                                         CFRangeMake(0, attrString.length),
                                         path,
                                         nil)
    if let coreGraphics = coreGraphics {
      CTFrameDraw(frame, coreGraphics)
      coreGraphics.restoreGState()
    }
  }
    
  public override func drawShadow(inRect rectange: CGRect) {
    
  }
  
  public override func drawRadialGradient(inRect rectangle: CGRect, startColor: Color, stopColor: Color) {
    
  }
  
  public override func prepareForReuse() {
    super.prepareForReuse()
  }
}

#endif
