//
//  MacApplication.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

#if os(macOS)

import Foundation
import AppKit

public class MacApplication: Application {
  
  let app: NSApplication!
  let delegate: AppDelegate

  override init(with window: Window) {
    app = NSApplication.shared
    app.setActivationPolicy(.regular)
    
    delegate = AppDelegate()
    delegate.window = window
    app.delegate = delegate

    super.init(with: window)
  }
  
  public override var iconPath: String?  {
    didSet {
      if let iconPath = iconPath {
        NSApp.applicationIconImage = NSImage(contentsOfFile: iconPath)
      } else {
        NSApp.applicationIconImage = nil
      }
    }
  }
  
  public override func launch() {
    Cursor.shared = MacCursor()
    app.run()
  }
  
  public override func terminate() {
    app.terminate(nil)
  }
  
  public override func add(window: Window, asChildOf parentWindow: Window? = nil) {
    var frame = window.rootView.frame
    
    // macOS co-ordinate system is flipped vertically
    if let parentWindow = parentWindow {
      frame.origin.x += parentWindow.position.x
      frame.origin.y = (parentWindow.position.y + parentWindow.rootView.frame.height)
                     - frame.origin.y
      frame.origin.y -= frame.height
    }
    
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
    
    let macWindow = MacWindow(contentRect: frame,
                              styleMask: styleMask,
                              backing: .buffered,
                              defer: false)
    let macView = MacView(frame: frame, suitWindow: window)
    macWindow.contentView = macView
    window.macWindow = macWindow
    window.macWindow.window = window
    window.platformWindowDelegate = window.macWindow
    window.macWindow.mouseEventDelegate = window
    window.macWindow.keyEventDelegate = window
    
    super.add(window: window, asChildOf: parentWindow)
    
    if let parentWindow = parentWindow {
      parentWindow.macWindow.addChildWindow(macWindow, ordered: .above)
      macWindow.makeKey()
    } else {
      macWindow.makeKeyAndOrderFront(self)
    }
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
      window.rootView.invalidateLayout()
      window.redrawManager.redraw(view: window.rootView)
    }
  }
}

#endif
