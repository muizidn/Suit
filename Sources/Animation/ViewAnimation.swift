//
//  ViewAnimation.swift
//  Suit
//
//  Created by pmacro on 30/04/2019.
//

import Foundation

///
/// An animation that applies to a view.
///
class ViewAnimation<Container: Animatable>: Animation {
  /// The animation's unique ID.
  let id: Int
  
  /// The duration of the animation, in seconds.
  var duration: Double
  
  /// The delay, in seconds, before the animation starts.
  let delay: Double
  
  /// Reports the current running time of the animation, i.e. records the progress
  /// from 0 to `duration`.
  var runningTime = 0.0
  
  /// The view, typed by it's actual concrete view subclass.
  weak var typedView: Container?
  
  /// The target of the animation.
  weak var target: Animatable? {
    return typedView
  }
  
  /// The state of the view's animatable properties at the start of the animation.
  var from: AnimationProperties<Container>
  
  /// The state of the view's animatable properties at the end of the animation.
  var to: AnimationProperties<Container>
  
  /// The current state of the view's animatable properties.
  var current: AnimationProperties<Container>
  
  /// A closure that is executed once the animation completes.
  var completion: CompletionBlock?
  
  /// The type of easing to use in the animation.
  let easing: Easing
  
  /// Has the animation been cancelled?
  var cancelled = false
  
  init(id: Int,
       view: Container,
       from: AnimationProperties<Container>,
       to: AnimationProperties<Container>,
       duration: Double,
       delay: Double,
       easing: Easing,
       completion: CompletionBlock?) {
    self.id = id
    self.duration = duration
    self.typedView = view
    self.current = from
    self.from = from
    self.to = to
    self.delay = delay
    self.easing = easing
    self.completion = completion
  }
  
  internal func animate() {
    if runningTime >= delay {
      if let typedView = typedView {
        for propertyValue in current.propertyValues {
          let prop = from.propertyValues[propertyValue.key] as Any
          let new = to.propertyValues[propertyValue.key] as Any
                    
          var setter = propertyValue.value
          if setter.forwardingUpdate(with: easing,
                                     currentFrame: runningTime,
                                     oldValue: prop,
                                     newValue: new,
                                     duration: duration) {
            setter.forwardingWrite(to: typedView, at: propertyValue.key)
          }
        }
        
        DispatchQueue.main.async {
          if let view = typedView as? View {
            view.window.rootView.invalidateLayout()
            if let superview = view.superview {
              superview.forceRedraw()
            } else {
              view.forceRedraw()
            }
          }
        }
      }
    }
    
    runningTime += AnimationInterval
    if runningTime >= duration + delay {
      to.apply()
      cancel()
    }
  }
}
