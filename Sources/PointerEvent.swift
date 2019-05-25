//
//  MouseEvent.swift
//  Suit
//
//  Created by pmacro  on 13/01/2017.
//
//

import Foundation

#if os(macOS) || os(iOS)
import CoreGraphics
#endif

public enum PointerEventPhase {
  case started
  case ended
  case unknown
}

public enum PointerEventType {
  case drag
  case click
  case release
  case enter
  case exit
  case move
  case scroll
}

public struct PointerEvent {
  public var type: PointerEventType = .click
  public var eventCount = 1
  public var phase: PointerEventPhase = .unknown
  public var deltaX: CGFloat = 0
  public var deltaY: CGFloat = 0
  public var location: CGPoint = CGPoint(x: 0, y: 0)
  var dragStartingPoint: CGPoint?
}
