//
//  AnimationTimer.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

import Foundation

///
/// A timer that will invoke a callback function on each `tick`.  If supported by the
/// platform, implementions adopting this protocol should be vsynced.
///
protocol AnimationTimer {
  func start()
  func stop()
  static func create() -> AnimationTimer
  var callback: (() -> Void)? { get set }
}
