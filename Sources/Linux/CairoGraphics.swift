//
//  CairoGraphics.swift
//  Editor
//
//  Created by pmacro  on 29/01/2019.
//

import Foundation
#if os(Linux)

import X11
import Cairo
import Pango

public class CairoGraphics: Graphics {
  
  public typealias Cairo = OpaquePointer
  public typealias CairoSurface = OpaquePointer
  
  internal weak var window: Window?
  internal static var cachedCairo: Cairo!
  internal static var cachedSurface: CairoSurface!
  
  var cairoStack = [Cairo]()
  
  internal var cairo: Cairo {
    set {
      cairoStack.append(newValue)
    }
    
    get {
      return cairoStack.last!
    }
  }
  
  internal var surface: CairoSurface!
  
  internal var font: Font?
  public var lineWidth: Double = 1
  public var point: CGPoint = .zero
  public let scale: Double
  
  public class func createForX11(inWindow window: Window) -> Graphics {
    return CairoGraphics(window: window)
  }
  
  public init(window: Window) {
    self.window = window
    scale = Double(window.x11Window.scale)
    prepareForReuse()
  }
  
  public func prepareForReuse() {
    surface = window?.x11Window.surface
    
    cairo = cairo_create(surface)
    cairo_set_antialias(cairo, cairo_antialias_t(rawValue: 6))
    
    cairo_scale(cairo, scale, scale)
  }
  
  public func set(color: Color) {
    cairo_set_source_rgba(cairo,
                          color.redValue,
                          color.greenValue,
                          color.blueValue,
                          color.alphaValue)
  }
  
  public func set(font: Font) {
    self.font = font
  }
  
  public func draw(text: String,
                   inRect rectangle: CGRect,
                   horizontalArrangement: HorizontalTextArrangement = .left,
                   verticalArrangement: VerticalTextArrangement = .top,
                   with lineAttributes: [TextAttribute]?,
                   wrapping: TextWrapping) {
    let rect = translateRectangleToWindowCoordinates(rectangle)

    guard !rect.size.width.isNaN, !rect.size.height.isNaN else {
      print("Warning: invalid rect passed to CairoGraphics.draw:text:inRect...")
      return
    }

    let layout = pango_cairo_create_layout(cairo)

    switch wrapping {
      // It only makes sense to set an undefined width when we're left aligned.
      case .none where horizontalArrangement == .left:
        pango_layout_set_width(layout, -1)
      case .word:
        pango_layout_set_wrap(layout, PANGO_WRAP_WORD)
        pango_layout_set_width(layout, Int32(rect.size.width) * PANGO_SCALE)
      case .character:
        pango_layout_set_wrap(layout, PANGO_WRAP_CHAR)
        pango_layout_set_width(layout, Int32(rect.size.width) * PANGO_SCALE)
      default:
        pango_layout_set_width(layout, Int32(rect.size.width) * PANGO_SCALE)
    }

    pango_layout_set_text (layout, text, -1)
    let font = self.font ?? Font(size: 8, family: "Helvetica")
    let desc = pango_font_description_from_string ("\(font.family) \(font.size)")
    pango_font_description_set_weight(desc, font.weight.pangoWeight)

    pango_layout_set_font_description (layout, desc)
    let attrList = pango_attr_list_new()
 
    let stringCount = text.count
    
    if let lineAttributes = lineAttributes {
      for attribute in lineAttributes
        where attribute.range.upperBound <= stringCount && attribute.range.count > 0
      {
        let attr = pango_attr_foreground_new(UInt16(attribute.color.redValue * 65535),
                                             UInt16(attribute.color.greenValue * 65535),         
                                             UInt16(attribute.color.blueValue * 65535))
        attr?.pointee.start_index = UInt32(attribute.range.lowerBound)
        attr?.pointee.end_index = UInt32(attribute.range.upperBound)
        pango_attr_list_insert(attrList, attr)
      }
    }

    pango_font_description_free(desc)
    
    switch (horizontalArrangement) {
    case .left:
      pango_layout_set_alignment(layout, PANGO_ALIGN_LEFT)
    case .center:
      pango_layout_set_alignment(layout, PANGO_ALIGN_CENTER)
    case .right:
      pango_layout_set_alignment(layout, PANGO_ALIGN_RIGHT)
    }
    
    let width = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    let height = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    
    pango_layout_get_pixel_size(layout, width, height)
    
    switch (verticalArrangement) {
    case .top:
      cairo_move_to(cairo, Double(rect.origin.x), Double(rect.origin.y))
    case .center:
      let yPos = rect.origin.y + ((rect.height - CGFloat(height.pointee)) / 2)
      cairo_move_to(cairo, Double(rect.origin.x), Double(yPos))
    case .bottom:
      let yPos = rect.origin.y + rect.height - CGFloat(height.pointee)
      cairo_move_to(cairo, Double(rect.origin.x), Double(yPos))
    }

    pango_layout_set_attributes(layout, attrList)
    pango_cairo_show_layout (cairo, layout)

    g_object_unref(UnsafeMutableRawPointer(layout)!)
    pango_attr_list_unref(attrList)
  }
  
  public func size(of string: String, wrapping: TextWrapping) -> CGRect {
    let layout = pango_cairo_create_layout(cairo)

    switch wrapping {
      case .none:
        pango_layout_set_width(layout, -1)
      case .word:
        pango_layout_set_wrap(layout, PANGO_WRAP_WORD)
      case .character:
        pango_layout_set_wrap(layout, PANGO_WRAP_CHAR)
    }

    pango_layout_set_text(layout, string, -1)
    let font = self.font ?? Font(size: 8, family: "Helvetica")
    let desc = pango_font_description_from_string("\(font.family) \(font.size)")
    pango_font_description_set_weight(desc, font.weight.pangoWeight)
    pango_layout_set_font_description(layout, desc)
    pango_font_description_free(desc)

    let width = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    let height = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    
    pango_layout_get_pixel_size(layout, width, height)

    return CGRect(x: 0, 
                  y: 0,
                  width: CGFloat(width.pointee),
                  height: CGFloat(height.pointee))
  }
  
  public func draw(rectangle: CGRect) {
    let rect = translateRectangleToWindowCoordinates(rectangle)

    cairo_rectangle(cairo,
                    Double(rect.origin.x),
                    Double(rect.origin.y),
                    Double(rect.size.width),
                    Double(rect.size.height))
  }
  
  public func draw(roundedRectangle: CGRect, cornerRadius radius: Double) {
    var rect = translateRectangleToWindowCoordinates(roundedRectangle)
    rect = NSInsetRect(rect, 0.5, 0.5)

    let x         = Double(rect.origin.x)
    let y         = Double(rect.origin.y)
    let width     = Double(rect.width)
    let height    = Double(rect.height)
    
    cairo_move_to(cairo, x + radius, y)
    cairo_line_to(cairo, x + width - radius, y)
    cairo_curve_to(cairo,x + width, y, x + width, y, x + width, y + radius)
    cairo_line_to(cairo, x + width, y + height - radius)
    cairo_curve_to(cairo,x + width, y + height, x + width, y + height, x + width - radius, y + height)
    cairo_line_to(cairo, x + radius, y + height)
    cairo_curve_to(cairo, x, y + height, x, y + height, x, y + height - radius)
    cairo_line_to(cairo, x, y + radius)
    cairo_curve_to(cairo, x, y, x, y, x + radius, y)
  }
  
  public func clip(rectangle: CGRect) {
    draw(rectangle: rectangle)
    clip()
  }
  
  public func clip(roundedRectangle: CGRect, cornerRadius: Double) {
    draw(roundedRectangle: roundedRectangle, cornerRadius: cornerRadius)
    clip()
  }
  
  public func clip() {
    cairo_clip(cairo)
  }
  
  public func fill() {
    cairo_fill(cairo)
  }
  
  public func stroke() {
    cairo_set_line_width(cairo, lineWidth)
    cairo_stroke(cairo)
  }
  
  public func fill(rectangle: CGRect, usingImageMask image: Image, imageMode: ImageMode) {

    guard case let .path(imagePath) = image.storageType else {
      fatalError("Unsupported image type")
    }    

    let rect = translateRectangleToWindowCoordinates(rectangle)
    
    let image = cairo_image_surface_create_from_png(imagePath)
    
    let width = CGFloat(cairo_image_surface_get_width(image))
    let height = CGFloat(cairo_image_surface_get_height(image))
    
    let horizontalScale: Double
    let verticalScale: Double
    let xPos: Double
    let yPos: Double
    
    switch imageMode {
    case .fill:
      horizontalScale = Double(width / rect.width)
      verticalScale = Double(height / rect.height)
      xPos = Double(rect.origin.x) * horizontalScale
      yPos = Double(rect.origin.y) * verticalScale
    case .maintainAspectRatio:
      let horizontal = Double(width / rect.width)
      let vertical = Double(height / rect.height)
      horizontalScale = max(horizontal, vertical)
      verticalScale = horizontalScale
      
      let scaledImageWidth = width * CGFloat(1 / horizontalScale)
      let scaledImageHeight = height * CGFloat(1 / verticalScale)
      
      xPos = Double(rect.origin.x
        + ((rect.width - scaledImageWidth) / 2))
        * horizontalScale
      yPos = Double(rect.origin.y
        + ((rect.height - scaledImageHeight) / 2))
        * verticalScale
    }
    
    cairo_scale(cairo, 1 / horizontalScale, 1 / verticalScale)
    
    cairo_mask_surface(cairo, image, xPos, yPos)
    cairo_surface_destroy(image)
  }
  
  public func draw(imagePath: String, rectangle: CGRect, imageMode: ImageMode) {
    let rect = translateRectangleToWindowCoordinates(rectangle)
    
    let image = cairo_image_surface_create_from_png(imagePath)
    let width = CGFloat(cairo_image_surface_get_width(image))
    let height = CGFloat(cairo_image_surface_get_height(image))
    
    let horizontalScale: Double
    let verticalScale: Double
    let xPos: Double
    let yPos: Double
    
    switch imageMode {
    case .fill:
      horizontalScale = Double(width / rect.width)
      verticalScale = Double(height / rect.height)
      xPos = Double(rect.origin.x) * horizontalScale
      yPos = Double(rect.origin.y) * verticalScale
    case .maintainAspectRatio:
      let horizontal = Double(width / rect.width)
      let vertical = Double(height / rect.height)
      horizontalScale = max(horizontal, vertical)
      verticalScale = horizontalScale
      
      let scaledImageWidth = width * CGFloat(1 / horizontalScale)
      let scaledImageHeight = height * CGFloat(1 / verticalScale)
      
      xPos = Double(rect.origin.x
        + ((rect.width - scaledImageWidth) / 2))
        * horizontalScale
      yPos = Double(rect.origin.y
        + ((rect.height - scaledImageHeight) / 2))
        * verticalScale
    }
    
    //  cairo_image_surface_blur(image, 1)
    cairo_scale(cairo, 1 / horizontalScale, 1 / verticalScale)
    cairo_set_source_surface (cairo,
                              image,
                              xPos,
                              yPos)
    cairo_paint(cairo)
    cairo_surface_destroy(image)
  }
  
  public func draw(image: Image, rectangle: CGRect, imageMode: ImageMode) {
    switch image.storageType {
      case .path(let imagePath):
      draw(imagePath: imagePath, rectangle: rectangle, imageMode: imageMode)
    }
  }
  
  public func drawShadow(inRect rectangle: CGRect) {
    let rect = translateRectangleToWindowCoordinates(rectangle)
    
    let shadow = cairo_image_surface_create(CairoFormat.argb32.value,
                                            Int32(rect.width),
                                            Int32(rect.height))
    let cr = cairo_create(shadow)!
    
    let shadowStart = Color(red: 0, green: 0, blue: 0, alpha: 0.3)
    let shadowEnd = Color(red: 0, green: 0, blue: 0, alpha: 0.1)
    
    drawRadialGradient(inRect: rect,
                       startColor: shadowStart,
                       stopColor: shadowEnd,
                       usingCairo: cr)
    
    //    cairo_image_surface_blur(shadow, 10)
    
    cairo_set_source_surface (cairo,
                              shadow,
                              Double(rect.origin.x),
                              Double(rect.origin.y))
    
    cairo_paint(cairo)
    cairo_surface_flush(shadow)
    cairo_surface_destroy(shadow)
    cairo_destroy(cr)
  }
  
  public func drawGradient(inRect rectangle: CGRect,
                           startColor: Color,
                           stopColor: Color) {
    drawGradient(inRect: rectangle,
                 startColor: startColor,
                 stopColor: stopColor,
                 usingCairo: cairo)
  }
  
  private func drawGradient(inRect rectangle: CGRect,
                            startColor: Color,
                            stopColor: Color,
                            usingCairo cairo: Cairo) {
    let rect = translateRectangleToWindowCoordinates(rectangle)
    
    let pattern = cairo_pattern_create_linear (Double(rect.origin.x + (rect.width / 2)),
                                               Double(rect.origin.y),
                                               Double(rect.origin.x + (rect.width / 2)),
                                               Double(rect.origin.y + rect.height))
    
    cairo_pattern_add_color_stop_rgba (pattern,
                                       0,
                                       startColor.redValue,
                                       startColor.greenValue,
                                       startColor.blueValue,
                                       startColor.alphaValue)
    cairo_pattern_add_color_stop_rgba (pattern,
                                       1,
                                       stopColor.redValue,
                                       stopColor.greenValue,
                                       stopColor.blueValue,
                                       startColor.alphaValue)
    cairo_rectangle (cairo,
                     Double(rect.origin.x),
                     Double(rect.origin.y),
                     Double(rect.size.width),
                     Double(rect.size.height))
    
    cairo_set_source (cairo, pattern)
    cairo_fill(cairo)
    cairo_pattern_destroy (pattern)
  }
  
  public func drawRadialGradient(inRect rectangle: CGRect,
                                 startColor: Color,
                                 stopColor: Color) {
    drawRadialGradient(inRect: rectangle,
                       startColor: startColor,
                       stopColor: stopColor,
                       usingCairo: cairo)
  }
  
  public func drawRadialGradient(inRect rectangle: CGRect,
                                 startColor: Color,
                                 stopColor: Color,
                                 usingCairo cairo: Cairo) {
    let rect = translateRectangleToWindowCoordinates(rectangle)
    
    let pattern = cairo_pattern_create_radial (Double(rect.width / 2),
                                               Double(rect.height / 2),
                                               Double(rect.width / 25),
                                               Double(rect.width / 2),
                                               Double(rect.height / 2),
                                               Double(rect.width / 2))
    
    cairo_pattern_add_color_stop_rgba (pattern,
                                       0,
                                       startColor.redValue,
                                       startColor.greenValue,
                                       startColor.blueValue,
                                       startColor.alphaValue)
    
    cairo_pattern_add_color_stop_rgba (pattern,
                                       1,
                                       stopColor.redValue,
                                       stopColor.greenValue,
                                       stopColor.blueValue,
                                       stopColor.alphaValue);
    
    cairo_set_source (cairo, pattern);
    cairo_arc (cairo, Double(rect.width / 2),
               Double(rect.height / 2),
               Double(rect.width / 2), 0, 2 * .pi);
    cairo_fill (cairo);
    cairo_pattern_destroy (pattern);
  }
  
  public func flush() {
    cairo_surface_flush(surface)
    
    // cairo_surface_destroy(surface)
    
    let cr = cairoStack.removeLast()
    cairo_destroy(cr)
  }
  
  public func translateRectangleToWindowCoordinates(_ rectangle: CGRect) -> CGRect {
    var rect = rectangle
    rect.origin.x += point.x
    rect.origin.y += point.y
    return rect
  }
}

enum CairoFormat: Int32 {
  case invalid   = -1
  case argb32    = 0
  case rgb24     = 1
  case a8        = 2
  case a1        = 3
  case rgb16_565 = 4
  case rgb30     = 5
  
  var value: cairo_format_t {
    get {
      return cairo_format_t(rawValue: self.rawValue)
    }
  }
}

#endif
