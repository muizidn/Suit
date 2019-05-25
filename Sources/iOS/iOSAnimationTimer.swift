//
//  iOSAnimationTimer.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

#if os(iOS)

import Foundation
import UIKit

class iOSAnimationTimer: AnimationTimer {
  // Wrap CADisplay link in order to conform to AnimationTimer.  It can't be extended, unfortunately.
  var displayLink: CADisplayLink!
  var callback: (() -> Void)?
  
  @objc
  func invokeCallback() {
    callback?()
  }
  
  func start() {
    displayLink.isPaused = false
  }
  
  func stop() {
    displayLink.isPaused = true
  }
  
  static func create() -> AnimationTimer {
    let timer = iOSAnimationTimer()
    let displayLink = CADisplayLink(target: timer, selector: #selector(invokeCallback))
    displayLink.add(to: .current, forMode: .commonModes)
    timer.displayLink = displayLink
    timer.stop()
    return timer
  }
}

#endif
