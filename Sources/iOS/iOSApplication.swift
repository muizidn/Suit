//
//  iOSApplication.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

#if os(iOS)

import Foundation
import UIKit

public class iOSApplication: Application {
  
  override init(with window: Window) {
    AnimationFPS = Double(UIScreen.main.maximumFramesPerSecond)
    AnimationInterval = 1 / AnimationFPS
    
    // Make room for the status bar.
    window.titleBarHeight += 20
    window.titleBar?.topSpace = 30
    window.titleBar?.drawsSystemWindowButtons = false
    
    super.init(with: window)
    _supportsTouch = true
  }
  
  public override func launch() {
    UIApplicationMain(CommandLine.argc,
                      UnsafeMutableRawPointer(CommandLine.unsafeArgv)
                        .bindMemory(to: UnsafeMutablePointer<Int8>.self, capacity: Int(CommandLine.argc)),
                      NSStringFromClass(UIApplication.self),
                      NSStringFromClass(iOSAppDelegate.self))
  }
}

#endif
