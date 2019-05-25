//
//  AnimationTests.swift
//  SuitTests
//
//  Created by pmacro  on 02/05/2019.
//

import Foundation
import XCTest
import SuitTestUtils
@testable import Suit

///
/// A test animatable implementation.
///
class TestAnimatable: Animatable {
  var animatableProperty = 0
  var animatableFontProperty: Font = .ofType(.system, category: .medium)
  
  func generateAnimatableProperties<T>(in properties: AnimatableProperties<T>) where T : Animatable {
    if let properties = properties as? AnimatableProperties<TestAnimatable> {
      properties.add(\.animatableProperty)
      properties.add(\.animatableFontProperty)
    }
  }
}

class AnimationTests: XCTestCase {

  ///
  /// A basic test to ensure that animations successfully update animatable properties incrementally,
  /// and that at the end of an animation, the expected values are set.
  ///
  func testSimpleAnimation() {
    let animatable = TestAnimatable()
    let startValue = 0
    let endValue = 100
    
    animatable.animatableProperty = startValue
    
    let animationCompleted = XCTestExpectation(description: "animationCompleted")

    animatable.animate(duration: 2, changes: {
      animatable.animatableProperty = endValue
    }, completion: {
      animationCompleted.fulfill()
    })
    
    // Check that the animation starts, but does not yet complete.
    sleep(1)
    XCTAssert(animatable.animatableProperty > startValue && animatable.animatableProperty < endValue)
    
    wait(for: [animationCompleted], timeout: 1.1)
    // Now check that the animation completes with the expected end value.
    XCTAssert(animatable.animatableProperty == endValue)
  }
  
  func testFontAnimation() {
    let animatable = TestAnimatable()
    animatable.animatableFontProperty.size = 10
    
    let animationCompleted = XCTestExpectation(description: "animationCompleted")
    
    animatable.animate(duration: 2, changes: {
      animatable.animatableFontProperty.size = 50
    }, completion: {
      animationCompleted.fulfill()
    })

    // Check that the animation starts, but does not yet complete.
    sleep(1)
    XCTAssert(animatable.animatableFontProperty.size > 10 && animatable.animatableFontProperty.size < 50)
    
    wait(for: [animationCompleted], timeout: 1.1)
    // Now check that the animation completes with the expected end value.
    XCTAssert(animatable.animatableFontProperty.size == 50)
  }
}
