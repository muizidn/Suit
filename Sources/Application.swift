//
//  Application.swift
//  suit
//
//  Created by pmacro  on 29/05/2018.
//

import Foundation

///
/// All Suit-based applications start with an instance of `Application`.  It manages your
/// application windows and the application lifecycle.
///
public class Application {
  
  /// The main window for the application.
  var mainWindow: Window
  
  /// All non-main windows in the application.
  var windows: [Window] = []
  
  internal var _supportsTouch = false
  
  /// Indicates whether or not the system supports touch input, such as on a mobile device.  You can use this
  /// property at runtime to determine whether or not your interface needs to be touch-optimized.
  public var supportsTouch: Bool {
    return _supportsTouch
  }
  
  /// The path of the application's icon file.
  public var iconPath: String?
  
  /// The application singleton.
  internal static var instance: Application?
  
  /// The singleton Application instance.  Calling this before calling create(with:) will
  /// result in a fatal error.
  public static var shared: Application {
    if let instance = instance {
      return instance
    }
    
    fatalError("Application has not been created.")
  }
  
  ///
  /// Creates the singleton Application instance and returns it.  After calling this
  /// function, the application instance is also available via the static `shared` var.
  ///
  /// This function creates an platform-specific version of Application.  For this reason
  /// you cannot instantiate an Application manually.
  ///
  public static func create(with window: Window) -> Application {
    #if os(macOS)
    let application = MacApplication(with: window)
    #endif
    
    #if os(iOS)
    let application = iOSApplication(with: window)
    #endif

    #if os(Linux)
    let application = X11Application(with: window)
    #endif
    
    Application.instance = application
    return application
  }
  
  init(with window: Window) {
    self.mainWindow = window
    windows.append(window)
    Application.instance = self
  }
  
  ///
  /// Adds a new window to the application and displays it.
  ///
  /// - parameter window: the window to add.
  /// - parameter parentWindow: the window that is `window`'s parent, or nil if `window`
  ///  is a root window.
  ///
  public func add(window: Window, asChildOf parentWindow: Window? = nil) {
    window.windowDidLaunch()
    window.rootView.forceRedraw()
    windows.append(window)

    if let parentWindow = parentWindow {
      parentWindow.childWindows.append(window)
      window.parentWindow = parentWindow
    }
  }

  ///
  /// Launches the application.
  ///
  public func launch() {}
  
  ///
  /// Kills the application.
  ///
  public func terminate() {}
}
