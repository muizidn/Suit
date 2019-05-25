//
//  TestPlatformWindowDelegate.swift
//  SuitTests
//
//  Created by pmacro  on 07/02/2019.
//

import Foundation
@testable import Suit

class TestPlatformWindowDelegate: PlatformWindowDelegate {
  var position: CGPoint = .zero
  
  func move(to: CGPoint) {}
    
  func updateWindow() {}
  
  func updateWindow(rect: CGRect) {}
  
  func zoom() {}
  
  func minimize() {}
  
  func close() {}
  
  func center() {}
  
  func resize(to size: CGSize) {}
  
  func applyMenu(_ menu: Menu) {}
  
  func bringToFront() {}
  
  func setAlwaysOnTop() {}
}
