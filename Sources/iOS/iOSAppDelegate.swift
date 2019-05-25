//
//  iOSAppDelegate.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

#if os(iOS)

import Foundation
import UIKit

public class iOSAppDelegate: NSObject, UIApplicationDelegate, PlatformWindowDelegate {
  
  var window: Window!
  var uiWindow: UIWindow!
  var suitView: iOSView?
  
  var position = CGPoint.zero
  
  func move(to: CGPoint) {}
  func zoom() {}
  func minimize() {}
  func close() {}
  
  func updateWindow() {
    suitView?.layer.setNeedsDisplay()
  }
  
  func updateWindow(rect: CGRect) {
    updateWindow()
//    suitView?.layer.setNeedsDisplay(rect)
  }
  
  public func applicationWillEnterForeground(_ application: UIApplication) {
    updateWindow()
  }
  
  /// VSYnc? https://stackoverflow.com/questions/3202777/how-to-obtain-cgcontextref-from-uiview-or-uiwindow-for-debugging-outside-draw-me?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
  public func applicationDidFinishLaunching(_ application: UIApplication) {
    window = Application.shared.mainWindow
    window.rootView.frame = UIScreen.main.bounds
    uiWindow = UIWindow(frame: UIScreen.main.bounds)
    
    suitView = iOSView(frame: UIScreen.main.bounds)
    suitView?.suitWindow = window
    suitView?.backgroundColor = .white
    
    let component = iOSComponent()
    component.suitContainerView = suitView
    component.pointerEventDelegate = window
    uiWindow.rootComponent = component
    window.platformWindowDelegate = self
    
    uiWindow.makeKeyAndVisible()
    suitView?.layer.setNeedsDisplay()
  }
}

#endif
