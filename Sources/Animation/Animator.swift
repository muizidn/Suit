//
//  Animator.swift
//  suit
//
//  Created by pmacro on 22/05/2018.
//

import Foundation

/// A callback that takes no params and returns Void.
public typealias CompletionBlock = () -> Void

/// The queue that animations are synced through.
let AnimationAccessQueue = DispatchQueue(label: "Suit.AnimationAccessQueue")

///
/// Animator schedules and manages animations.
///
/// This class is intentionally `internal` for now.  It's implementation may change
/// significantly in the future.  It will be opened up for use as an API at a later time.
///
final class Animator {
  
  /// The timer responsible for scheduling and executing each animation `tick`.
  var timer: AnimationTimer
  
  /// All active animations.
  fileprivate var animations: [Animation] = []
  
  /// The ID generator for animations.
  private static var animationId = 0
  
  /// A singleton Animator instance.
  static let instance = Animator()
  
  var isAnimating = false
  
  ///
  /// Creates an Animator, configuring its `timer` for the current platform OS.
  ///
  private init() {
    #if os(macOS)
    timer = MacAnimationTimer.create()
    #elseif os(iOS)
    timer = iOSAnimationTimer.create()
    #else
    timer = RepeatingTimer.create()
    #endif
    
    timer.callback = { [weak self] in
      self?.animate()
    }
    
    timer.start()
  }
  
  ///
  /// This is invoked on each `tick` of the animation timer.  It triggers the incremental
  /// update of each Animatable that is part of an active animation.
  ///
  private func animate() {
    AnimationAccessQueue.async { [weak self] in
      guard let `self` = self else { return }
      
      for animation in self.animations {
        if !animation.cancelled {
          animation.animate()
        }
      }
    }
  }
  
  ///
  /// Schedules an animation according to the supplied parameters, including the view being
  /// animated; the starting property values; and the property values at the end of
  /// the animation, along with the type of easing used to get there.
  ///
  /// - parameter view: the entity to animate.
  /// - parameter from: the state of the entity's animatable properties before starting the animation.
  /// - parameter to: the state of the entity's animatable properties at the end of the animation.
  /// - parameter duration: the duration of the animation, in seconds.
  /// - parameter delay: the delay, in seconds, before starting the animation.
  /// - parameter easing: the easing to use to get from the starting state to the ending state.
  /// - parameter completion: a closure that will be executed upon the completion of the animation.
  ///
  static func animate<Container: Animatable>(view: Container,
                                       from: AnimationProperties<Container>,
                                       to: AnimationProperties<Container>,
                                       duration: Double,
                                       delay: Double = 0,
                                       easing: Easing = .linear,
                                       completion: CompletionBlock? = nil) -> Animation {
    animationId += 1
    let animation = ViewAnimation(id: animationId,
                                  view: view,
                                  from: from,
                                  to: to,
                                  duration: duration,
                                  delay: delay,
                                  easing: easing,
                                  completion: completion)
    AnimationAccessQueue.async {
      instance.animations.append(animation)
    }
    
    return animation
  }
  
  ///
  /// Schedules an animation according to the supplied parameters, including the view being
  /// animated and the changes to be applied during the animation.
  ///
  /// - parameter view: the entity to animate.
  /// - parameter duration: the duration of the animation, in seconds.
  /// - parameter delay: the delay, in seconds, before starting the animation.
  /// - parameter easing: the easing to use to get from the starting state to the ending state.
  /// - parameter animations: the changes to be applied to `view` during the animation.
  /// - parameter completion: a closure that will be executed upon the completion of the animation.
  ///
  public static func animate<Container: Animatable>(view: Container,
                                              duration: Double,
                                              delay: Double,
                                              easing: Easing = .linear,
                                              animations: () -> Void,
                                              completion: CompletionBlock? = nil) -> Animation {
    
    let properties = AnimatableProperties<Container>()
    view.generateAnimatableProperties(in: properties)
    
    let fromProperties = AnimationProperties(from: view, properties: properties)
    
    // Apply the animations so we know what our end goal is.
    animations()
    let toProperties = AnimationProperties(from: view, properties: properties)
    
    // Reset the state to before we invoked `animations()` so that our animation starts from
    // the correct state.
    fromProperties.apply()
    
    return animate(view: view,
                   from: fromProperties,
                   to: toProperties,
                   duration: duration,
                   delay: delay,
                   easing: easing,
                   completion: completion)
  }
  
  ///
  /// Cancels all active animations for `view`.
  ///
  /// - parameter view: the view whose animations should be cancelled.
  ///
  static func cancelAnimations<T: EquatableAnimatable>(for view: T) {
    AnimationAccessQueue.async {
      for animation in instance.animations {
        if let target = animation.target as? T, target == view {
          removeAnimation(animation)
        }
      }
    }
  }

  ///
  /// Remove `animation` from the list of active animations, preventing any further
  /// changes to the animated view's properties.  Calling this also invokes the completion
  /// callback for the animation.
  ///
  static func removeAnimation(_ animation: Animation) {
    if let index = instance.animations.firstIndex(where: { $0.id == animation.id }) {
      instance.animations.remove(at: index)
       DispatchQueue.main.async {
        animation.completion?()
        
        if let animation = animation as? ViewAnimation<View>,
           let view = animation.typedView
        {
          if let superview = view.superview {
            view.window.redrawManager.redraw(view: superview)
          } else {
            view.forceRedraw()
          }
        }
      }
    }
  }
}
