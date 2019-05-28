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

  var button: Button!
  
  override func setUp() {
    button = Button(ofType: .rounded)
    button.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
    window.rootView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    window.rootView.add(subview: button)
  }
  
  override func tearDown() {
    button.removeFromSuperview()
  }
  
  ///
  /// Test that a button press triggers the callback.
  ///
  func testButtonPress() {
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
  
  func testButtonRolloverStateChange() {
    button.changesStateOnRollover = true
    PointerEvent.enter(view: button)
    
    XCTAssert(button.state == .focused,
              "Expected button to be in `focused` state after rollover.")
  }
  
  ///
  /// Ensures that a button with a disabled state does not alter its state on rollover, press etc., and does
  /// not invoke the didPress callbacks.
  ///
  func testButtonDisablement() {
    let button = Button(ofType: .rounded)
    button.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
    button.isEnabled = false
    
    window.rootView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    window.rootView.add(subview: button)
    
    var didPressButton = false
    
    button.onPress = {
      didPressButton = true
    }
    
    PointerEvent.clickOn(view: button)
    
    XCTAssert(!didPressButton, "Expected button press to not fire when button is disabled")
    XCTAssert(button.state == .disabled,
              "Expected button to be in `disabled` state after click on disabled button.")
    
    PointerEvent.releaseOn(view: button)
    
    XCTAssert(!didPressButton, "Expected button press to not fire when button is disabled")
    XCTAssert(button.state == .disabled,
              "Expected button to be in `disabled` state after release on disabled button.")
    
    // Test that rollover state changes don't happen when the button is disabled.
    //
    
    button.changesStateOnRollover = true
    PointerEvent.enter(view: button)
    
    XCTAssert(button.state == .disabled,
              "Expected button to be in `disabled` state after rollover on disabled button.")
  }
}
