//
//  ApplicationHelpers.swift
//  SuitTestUtils
//
//  Created by pmacro  on 28/02/2019.
//

import Foundation
@testable import Suit

public func createApplication(with window: Window) {
  Application.instance = TestApplication(with: window)
  window.platformWindowDelegate = TestPlatformWindowDelegate()
  window.windowDidLaunch()
}

public class TestApplication: Application {
  
  public override func add(window: Window, asChildOf parentWindow: Window? = nil) {
    window.platformWindowDelegate = TestPlatformWindowDelegate()
    super.add(window: window, asChildOf: parentWindow)
  }
  
}
