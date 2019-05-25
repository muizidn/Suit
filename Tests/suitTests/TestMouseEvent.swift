//
//  TestMouseEvent.swift
//  SuitTests
//
//  Created by pmacro  on 07/02/2019.
//

import Foundation
@testable import Suit

let clickEvent = { (location: CGPoint, clickCount: Int) in
  return PointerEvent(type: .click,
                    eventCount: clickCount,
                    phase: .started,
                    deltaX: 0,
                    deltaY: 0,
                    location: location,
                    dragStartingPoint: nil)
}
