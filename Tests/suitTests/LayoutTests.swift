//
//  LayoutTests.swift
//  SuitTests
//
//  Created by pmacro on 10/02/2019.
//

import XCTest
@testable import Suit
import Yoga

///
/// Simple tests intended to test the Suit-Yoga integration, but not Yoga itself.
///
class LayoutTests: XCTestCase {

  var rootView: View!

  override func setUp() {
    rootView = View(frame: .zero)
    rootView.flexDirection = .row
    rootView.width = 400~
    rootView.height = 400~
  }
  
  func testSetup() {
    rootView.invalidateLayout()
    
    XCTAssert(rootView.frame.width == 400)
    XCTAssert(rootView.frame.height == 400)
  }
  
  func testSingleSubview() {
    let subview = View(frame: .zero)
    subview.width = 50%
    subview.height = 50%
    
    rootView.add(subview: subview)
    
    rootView.invalidateLayout()
    
    XCTAssert(subview.frame.width == 200)
    XCTAssert(subview.frame.height == 200)
  }
  
  func testTwoSiblings() {
    rootView.flexDirection = .column
    let child1 = View(frame: .zero)
    child1.width = 100%
    child1.height = 50~
    
    let child2 = View(frame: .zero)
    child2.width = 100%
    child2.flexShrink = 1

    rootView.add(subview: child1)
    rootView.add(subview: child2)
    
    let subchild = View(frame: .zero)
    subchild.width = 25%
    subchild.height = 100%
    
    child2.add(subview: subchild)

    rootView.invalidateLayout()
    
    XCTAssert(child1.frame.width == 400)
    XCTAssert(child1.frame.origin.x == 0)
    XCTAssert(child1.frame.height == 50)
    XCTAssert(child1.frame.origin.y == 0)
    
    XCTAssert(child2.frame.width == 400)
    XCTAssert(child1.frame.origin.x == 0)
    XCTAssert(child2.frame.height == 350)
    XCTAssert(child2.frame.origin.y == 50)
    
    XCTAssert(subchild.frame.width == 100)
    XCTAssert(subchild.frame.height == 350)
    XCTAssert(subchild.frame.origin.x == 0)
  }
  
  func testMultipleRoots() {
    let root1 = View(frame: .zero)
    root1.width = 100~
    root1.height = 100~
    
    let root2 = View(frame: .zero)
    root2.width = 100~
    root2.height = 100~
    
    let child1 = View(frame: .zero)
    child1.width = 50%
    child1.height = 50%
    
    let child2 = View(frame: .zero)
    child2.width = 50%
    child2.height = 50%
    
    root1.add(subview: child1)
    root2.add(subview: child2)
    
    root1.invalidateLayout()
    root2.invalidateLayout()
    
    XCTAssert(root1.frame.width == 100)
    XCTAssert(root1.frame.height == 100)

    XCTAssert(root2.frame.width == 100)
    XCTAssert(root2.frame.height == 100)
    
    XCTAssert(child1.frame.width == 50)
    XCTAssert(child1.frame.height == 50)

    XCTAssert(child2.frame.width == 50)
    XCTAssert(child2.frame.height == 50)
  }
}
