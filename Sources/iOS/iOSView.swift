//
//  iOSView.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

#if os(iOS)

import Foundation
import UIKit


class iOSView: UIView {
  
  var suitWindow: Window?
  
  override func draw(_ layer: CALayer, in ctx: CGContext) {
    let start = Date()

    super.draw(layer, in: ctx)
    ctx.setAllowsAntialiasing(true)
    ctx.setAllowsFontSmoothing(true)
    ctx.setShouldAntialias(true)
    ctx.setShouldSmoothFonts(true)
    UIGraphicsPushContext(ctx)
    suitWindow?.redrawManager.redraw(target: suitWindow!.rootView)
    suitWindow?.rootView.draw()
    UIGraphicsPopContext()
    
    print("Draw took: \(Date().timeIntervalSince(start))s")
  }
}

#endif
