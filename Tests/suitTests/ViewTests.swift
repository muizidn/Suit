//
//  ViewTests.swift
//  SuitTests
//
//  Created by pmacros on 28/05/2019.
//

import XCTest
import Foundation
@testable import Suit
import SuitTestUtils

class ViewTests: XCTestCase {

  func testCoordinateConversion() {
    let root = View()
    root.width = 200~
    root.height = 200~
    
    window.rootView = root
    
    let subview = View()
    subview.width = 100~
    subview.height = 100~
    
    root.flexDirection = .columnReverse
    root.alignItems = .flexEnd
    root.add(subview: subview)
    
    root.invalidateLayout()
    
    XCTAssert(subview.frame.origin == CGPoint(x: 100, y: 100),
              "Expected subview to be at the end of the parent, both horizontally and vertically.")
    
    // Convert (150, 150) in window coordinates to coordinates in `subview`.
    let viewCoordinates = subview.windowCoordinatesInViewSpace(from: CGPoint(x: 150, y: 150))
    
    XCTAssert(viewCoordinates == CGPoint(x: 50, y: 50),
              "Expected converted coordinates in view to be (50, 50) but were \(viewCoordinates)")
  }
  
  func testScrollViewCoordinateConversion() {
    let root = View()
    root.width = 200~
    root.height = 200~
    
    window.rootView = root
    
    let subview = View()
    subview.width = 100~
    subview.height = 1000~
    
    let scrollView = ScrollView()
    scrollView.width = 100~
    scrollView.height = 100~
    scrollView.add(subview: subview)
    
    root.flexDirection = .columnReverse
    root.alignItems = .flexEnd
    root.add(subview: scrollView)
    root.invalidateLayout()

    scrollView.scroll(to: CGPoint(x: 0, y: -400))
    
    XCTAssert(scrollView.frame.origin == CGPoint(x: 100, y: 100),
              "Expected subview to be at the end of the parent, both horizontally and vertically.")
    
    // Convert (150, 150) in window coordinates to coordinates in `subview`.
    let viewCoordinates = subview.windowCoordinatesInViewSpace(from: CGPoint(x: 150, y: 150))
    
    XCTAssert(viewCoordinates == CGPoint(x: 50, y: 450),
              "Expected converted coordinates in view to be (50, 50) but were \(viewCoordinates)")

  }
  
}
