//
//  MacView.swift
//  Suit
//
//  Created by pmacro on 03/06/2018.
//

#if os(macOS)

import Foundation
import AppKit

class MacView: NSView {
  weak var suitWindow: Window?
  
  var isDarkMode: Bool {
    if #available(OSX 10.14, *) {
      if effectiveAppearance.name == .darkAqua {
        return true
      }
    }
    return false
  }
  
  init(frame frameRect: NSRect, suitWindow: Window) {
    super.init(frame: frameRect)
    self.suitWindow = suitWindow

    // Only necessary on versions prior to Mojave.
    wantsLayer = true
    layerContentsRedrawPolicy = .onSetNeedsDisplay
  }
  
  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var wantsUpdateLayer: Bool {
    return true
  }
  
  override func setNeedsDisplay(_ invalidRect: NSRect) {
    super.setNeedsDisplay(invalidRect)
    layer?.setNeedsDisplay(invalidRect)
  }
  
  override func makeBackingLayer() -> CALayer {
    return Layer(suitWindow: suitWindow)
  }
}

class Layer: CALayer {
  weak var suitWindow: Window?
  
  init(suitWindow: Window?) {
    super.init()
    self.suitWindow = suitWindow

    backgroundColor = Color.backgroundColor.cgColor
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func setNeedsDisplay() {
    super.setNeedsDisplay()
    
    contentsScale = suitWindow?.macWindow?.screen?.backingScaleFactor ?? contentsScale
  }

  override func draw(in ctx: CGContext) {
    super.draw(in: ctx)
    
    ctx.translateBy(x: 0, y: suitWindow!.rootView.frame.size.height)
    ctx.scaleBy(x: 1, y: -1)

    if let quartz = suitWindow?.graphics as? QuartzGraphics {
      quartz.coreGraphics = ctx
    }
    
    let dirtyRect = ctx.boundingBoxOfClipPath
    suitWindow?.rootView.draw(dirtyRect: dirtyRect)
  }
}

#endif
