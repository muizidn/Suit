//
//  PointerHelpers.swift
//  SuitTestUtils
//
//  Created by pmacro  on 10/04/2019.
//

import Foundation
@testable import Suit

extension PointerEvent {
  public static func clickOn(view: View) {
    let event = PointerEvent(type: .click,
                             eventCount: 1,
                             phase: .unknown,
                             deltaX: 0,
                             deltaY: 0,
                             location: view.frame.origin,
                             dragStartingPoint: nil)
    view.onPointerEvent(event)
  }
  
  public static func releaseOn(view: View) {
    let event = PointerEvent(type: .release,
                             eventCount: 1,
                             phase: .unknown,
                             deltaX: 0,
                             deltaY: 0,
                             location: view.frame.origin,
                             dragStartingPoint: nil)
    view.onPointerEvent(event)
  }
}
