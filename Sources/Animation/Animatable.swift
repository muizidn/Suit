//
//  Animatable.swift
//  Suit
//
//  Created by pmacro on 23/04/2019.
//

import Foundation

// What a name!!
/// An Animatable that is also equatable.
public typealias EquatableAnimatable = Animatable & Equatable

///
/// An animatable is an object whose properties can be altered by the animation system.
///
public protocol Animatable: AnyObject {

  ///
  /// An animatable entity needs to provide details of which of its properties
  /// can be animated.
  ///
  /// - parameter properties: the object instance in which to add animatable properties.
  ///
  func generateAnimatableProperties<T: Animatable>(in properties: AnimatableProperties<T>)
}

extension Animatable {

  @discardableResult
  public func animate(duration: Double, delay: Double = 0, easing: Easing = .linear, changes: () -> Void, completion: CompletionBlock? = nil) -> Animation? {
    return Animator.animate(view: self,
                            duration: duration,
                            delay: delay,
                            easing: easing,
                            animations: changes,
                            completion: completion)
  }
}
