//
//  MacAppDelegate.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

import Foundation

#if os(macOS)
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
  
  var window: Window!
  
  override init() {
    super.init()
  }
  
  func applicationWillFinishLaunching(_ notification: Notification) {
    let rect = CGRect(x: 0,
                      y: 0,
                      width: window.rootView.frame.width,
                      height: window.rootView.frame.height)
    
    let styleMask: NSWindow.StyleMask
    
    if window.hasTitleBar, window.drawsSystemWindowButtons {
      styleMask = [.resizable,
                   .titled,
                   .fullSizeContentView,
                   .closable,
                   .miniaturizable]
    } else {
      styleMask = [.resizable,
                   .fullSizeContentView]
    }
    
    let macWindow = MacWindow(contentRect: rect,
                              styleMask: styleMask,
                              backing: .buffered,
                              defer: false)
    
    let macView = MacView(frame: rect, suitWindow: window)
    macWindow.contentView = macView
    window.macWindow = macWindow
    window.macWindow.window = window
    window.platformWindowDelegate = window.macWindow
    window.macWindow.mouseEventDelegate = window
    window.macWindow.keyEventDelegate = window
    window.windowDidLaunch()
    window.redrawManager.redraw(view: window.rootView)
  }
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    window.macWindow.makeKeyAndOrderFront(NSApp)
    NSApp.activate(ignoringOtherApps: true)
  }
}

#endif
