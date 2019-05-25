//
//  Animation.swift
//  Suit
//
//  Created by pmacro on 30/04/2019.
//

import Foundation

///
/// Defines an animation.
///
public protocol Animation: class {
  var cancelled: Bool { get set }
  var id: Int { get }
  var target: Animatable? { get }
  var completion: CompletionBlock? { get set }
  func animate()
  func cancel()
}

extension Animation {
  
  ///
  /// Default cancellation implementation.  All animiation are expected to have the same
  /// cancellation logic, anyway.
  ///
  public func cancel() {
    AnimationAccessQueue.async { [weak self] in
      guard let `self` = self else { return }
      if !self.cancelled {
        Animator.removeAnimation(self)
      }
      self.cancelled = true
    }
  }
}
