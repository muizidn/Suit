//
//  ImageView.swift
//  SuitPackageDescription
//
//  Created by pmacro on 24/05/2018.
//

import Foundation

public enum ImageMode {
  case maintainAspectRatio
  case fill
}

///
/// A view that display an instance of `Image`.
///
public class ImageView: View {
  
  /// The image to draw in this view.
  public var image: Image?
  
  /// The mode to use when scaling the image.
  public var mode: ImageMode = .maintainAspectRatio
  
  /// If true, the image is used as a mask and is coloured using the value in `tintColor`.
  /// This is `false` by default.
  public var useImageAsMask = false
  
  /// The colour to tint the image when `useImageAsMask` is true.
  public var tintColor: Color = .black

  ///
  /// Draws the image into the view.
  ///
  public override func draw(rect: CGRect) {
    super.draw(rect: rect)
    
    if let image = image {
      if useImageAsMask {
        graphics.set(color: tintColor)
        graphics.fill(rectangle: rect, 
                      usingImageMask: image,
                      imageMode: mode)
      } else {
        graphics.draw(image: image,
                      rectangle: rect,
                      imageMode: mode)
      }
    }
  }
}
