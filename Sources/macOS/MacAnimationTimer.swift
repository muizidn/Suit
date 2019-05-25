//
//  MacAnimationTimer.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

#if os(macOS)

import Foundation

private let DisplayLinkBackgroundQueue = DispatchQueue(label: "DisplayLinkBackgroundQueue",
                                                       qos: .userInteractive,
                                                       attributes: .concurrent,
                                                       autoreleaseFrequency: .never,
                                                       target: nil)

typealias MacAnimationTimer = DisplayLink

extension DisplayLink: AnimationTimer {
  func stop() {
    cancel()
  }
  
  static func create() -> AnimationTimer {
    return DisplayLink(onQueue: DisplayLinkBackgroundQueue)!
  }
}

#endif
