//
//  Easing.swift
//  Suit
//
//  Created by pmacro on 23/04/2019.
//

import Foundation

///
/// Represents different types of easing, which can be used to update values for
/// animations.
///
public enum Easing {
  case linear
  case quadraticEaseIn
  case quadraticEaseOut
  case quadraticEaseInOut
  case sineEaseIn
  
  ///
  /// Calculates the amount for the animation given the following state information:
  ///
  /// - parameter currentFrame: the current frame in the animation.
  /// - parameter startValue: the start value of the property being animated.
  /// - parameter totalChange: the amount to be added to startValue by the end of the entire animation.
  /// - parameter totalFrames: the total number of frames in the animation.
  ///
  func calculateFrom(currentFrame: Double, startValue: Double, totalChange: Double, totalFrames: Double) -> Double {
    //  // t: current time, b: begInnIng value, c: change In value, d: duration
    
    switch self {
    case .linear:
      return totalChange * currentFrame / totalFrames + startValue
    case .quadraticEaseIn:
      let frameFraction = currentFrame / totalFrames
      return totalChange * frameFraction * frameFraction + startValue;
    case .quadraticEaseOut:
      let frameFraction = currentFrame / totalFrames
      return -totalChange * frameFraction * (frameFraction - 2) + startValue;
    case .quadraticEaseInOut:
      var temp = currentFrame / (totalFrames / 2)
      if temp < 1 {
        return totalChange / 2 * temp * temp + startValue
      }
      temp -= 1
      return -totalChange / 2 * (temp * (temp - 2) - 1) + startValue
    case .sineEaseIn:
      return -totalChange * cos(currentFrame / totalFrames * (.pi / 2)) + totalChange + startValue
    }
  }
}
