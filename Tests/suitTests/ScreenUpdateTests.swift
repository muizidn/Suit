//
//  ScreenUpdateTests.swift
//  SuitTests
//
//  Created by pmacro  on 15/03/2019.
//

import XCTest
import SuitTestUtils
@testable import Suit

///
/// Tests concerned with testing that content changes cause screen redrawing
/// at the correct location and of the correct size.
///
class ScreenUpdateTests: XCTestCase {

  ///
  /// Test that a simple view hierarchy updates the correct portion of the screen
  /// when redrawn.
  ///
  func testSimpleChildViewScreenUpdates() {
    let windowDelegate = UpdateRecordingWindowDelegate()
    window.platformWindowDelegate = windowDelegate

    let baseView = createView(ofType: View.self)
    let childView1 = createView(ofType: View.self)
    let childView2 = createView(ofType: View.self)

    baseView.add(subview: childView1)
    baseView.add(subview: childView2)
    
    baseView.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
    childView1.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    childView2.frame = CGRect(x: 150, y: 150, width: 200, height: 200)
    
    baseView.forceRedraw()
    
    XCTAssert(windowDelegate.screenUpdateHistory.last == baseView.frame)
    
    childView1.forceRedraw()
    XCTAssert(windowDelegate.screenUpdateHistory.last == childView1.frame)

    childView2.forceRedraw()
    XCTAssert(windowDelegate.screenUpdateHistory.last == childView2.frame)
  }
  
  ///
  /// Test that content inside a scroll view updates the screen in the correct place
  /// whenever redrawn.
  ///
  func testScrollViewScreenUpdates() {
    let windowDelegate = UpdateRecordingWindowDelegate()
    window.platformWindowDelegate = windowDelegate

    let baseView = createView(ofType: View.self)
    let scrollView = createView(ofType: ScrollView.self)
    let contentView = createView(ofType: View.self)
    
    scrollView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    contentView.frame = CGRect(x: -100, y: 0, width: 9999, height: 9999)

    scrollView.add(subview: contentView)
    baseView.add(subview: scrollView)

    // The content view should only trigger an update of the parts visible within the scroll view.
    contentView.forceRedraw()
    XCTAssert(windowDelegate.screenUpdateHistory.last == scrollView.frame)
  }
  
  ///
  /// Test that a complex layout containing a scroll view updates the screen
  /// in the expected place.
  ///
  func testUpdateWithinComplexScrolledLayout() {
    let windowDelegate = UpdateRecordingWindowDelegate()
    window.platformWindowDelegate = windowDelegate

    let baseView = createView(ofType: View.self)
    baseView.flexDirection = .rowReverse
    baseView.width = 1000~
    baseView.height = 1000~
    
    let contentView = createView(ofType: View.self)
    contentView.height = 100%
    contentView.width = 50%
    
    let topView = createView(ofType: View.self)
    topView.height = 50~
    topView.width = 100%
    contentView.add(subview: topView)
    
    let scrollView = createView(ofType: ScrollView.self)
    scrollView.width = 100%
    scrollView.flex = 1
    contentView.add(subview: scrollView)

    let bottomView = createView(ofType: View.self)
    bottomView.height = 450~
    bottomView.width = 100%
    contentView.add(subview: bottomView)
    
    baseView.add(subview: contentView)
    baseView.invalidateLayout()
    
    XCTAssert(scrollView.frame.height == 500)
    XCTAssert(scrollView.frame.width == 500)
    
    scrollView.forceRedraw()

    XCTAssert(windowDelegate.screenUpdateHistory.last == scrollView.frameInWindow)

    let scrollViewContentView = createView(ofType: View.self)
    scrollViewContentView.width = 1000~
    scrollViewContentView.height = 1000~
    scrollView.add(subview: scrollViewContentView)
    
    scrollView.invalidateLayout()
    scrollViewContentView.forceRedraw()
    XCTAssert(windowDelegate.screenUpdateHistory.last == scrollView.frameInWindow)
  }
  
  ///
  /// Tests frame calculations that are used to figure out which part of the screen
  /// needs updated.
  ///
  func testAffectedFrameCalculations() {
    let baseView = createView(ofType: View.self)
    let contentView = createView(ofType: View.self)

    baseView.frame = CGRect(x: 0, y: 0, width: 1000, height: 1000)
    contentView.frame = CGRect(x: 250, y: 250, width: 500, height: 500)
    
    baseView.add(subview: contentView)

    var frame = baseView.frameInWindow.intersection(contentView.frameInWindow)
    XCTAssert(frame == contentView.frameInWindow)

    // Add a scroll view to the mix.
    let scrollView = createView(ofType: ScrollView.self)
    scrollView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
    contentView.add(subview: scrollView)
    
    frame = baseView.frameInWindow.intersection(scrollView.frameInWindow)
    XCTAssert(frame == scrollView.frameInWindow)
    
    let scrolledView = createView(ofType: View.self)
    scrolledView.frame = CGRect(x: 0, y: 0, width: 1000, height: 1000)
    scrollView.add(subview: scrolledView)
    
    frame = baseView.frameInWindow.intersection(scrolledView.frameInWindow)
    // Should be the same since scrolledView is bigger than scrollView, so it's frame
    // should max out at the scroll view's size.
    XCTAssert(frame == scrollView.frameInWindow)
  }
}

///
/// A PlatformWindowDelegate implementation that records screen update rectangles.
///
class UpdateRecordingWindowDelegate: PlatformWindowDelegate {
  
  var screenUpdateHistory = [CGRect]()
  
  var position: CGPoint = .zero
  
  func move(to: CGPoint) {}
    
  func updateWindow() {
    screenUpdateHistory.append(.infinite)
  }
  
  func updateWindow(rect: CGRect) {
    screenUpdateHistory.append(rect)
  }
  
  func zoom() {}
  
  func minimize() {}
  
  func close() {}
  
  func center() {}
  
  func resize(to size: CGSize) {}
  
  func applyMenu(_ menu: Menu) {}
  
  func bringToFront() {}
  
  func setAlwaysOnTop() {}
}
