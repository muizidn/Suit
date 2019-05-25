//
//  ButtonTests.swift
//  SuitTests
//
//  Created by pmacro on 05/04/2019.
//

import Foundation
import XCTest
import SuitTestUtils
@testable import Suit

class ButtonTests: XCTestCase {

  ///
  /// Test that a button press triggers the callback.
  ///
  func testButtonPress() {
    let button = Button(ofType: .rounded)
    window.rootView.add(subview: button)
    
    var didPressButton = false
    
    button.onPress = {
      didPressButton = true
    }
    
    button.press()
    
    XCTAssert(didPressButton,
              "Expected button press callback to have been invoked after programmatic press.")
    
    didPressButton = false
    PointerEvent.clickOn(view: button)
    
    XCTAssert(button.state == .pressed,
              "Expected button to be in `pressed` state after click.")

    XCTAssert(!didPressButton,
              "Expected button click without release to NOT result in a button press callback invocation.")
    
    PointerEvent.releaseOn(view: button)
    
    XCTAssert(button.state == .focused,
              "Expected button to be focused after release.")

    XCTAssert(didPressButton,
              "Expected button press callback to have been invoked after pointer click.")
  }
  
  ///
  /// If you click on a button, then move the pointer away from the button's bounds and release
  /// it, that should not count as a button press.
  ///
  func testClickOnButtonButReleaseOutsideButton() {
    let button = Button(ofType: .rounded)
    button.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
    window.rootView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    window.rootView.add(subview: button)
    
    var didPressButton = false
    
    button.onPress = {
      didPressButton = true
    }

    PointerEvent.clickOn(view: button)
    
    XCTAssert(button.state == .pressed,
              "Expected button to be in `pressed` state after click.")
    
    let releaseEvent = PointerEvent(type: .release,
                                    eventCount: 1,
                                    phase: .unknown,
                                    deltaX: 0,
                                    deltaY: 0,
                                    location: .zero,
                                    dragStartingPoint: nil)
    _ = window.onPointerEvent(releaseEvent)
    
    XCTAssert(!didPressButton,
              "Expected button release outside button bounds to NOT result in a button press.")
    
    XCTAssert(button.state == .unfocused,
              "Expected button to be unfocused after release outside its bounds.")
  }
}
