//
//  AnimatableProperties.swift
//  Suit
//
//  Created by pmacro on 23/04/2019.
//

import Foundation

///
/// Stores the properties that are animatable on a view.
///
final public class AnimatableProperties<Container> {
  /// A type-erased array of animatable properties.  It's safe to assume these all
  /// map to values that conform to AnimatableViewProperty.
  var animatablePropertyKeyPaths = [PartialKeyPath<Container>]()

  ///
  /// Adding a key path here allows the corresponding property to participate
  /// in animations.
  ///
  public func add<T: AnimatableViewProperty>(_ keyPath: ReferenceWritableKeyPath<Container, T>) {
    animatablePropertyKeyPaths.append(keyPath)
  }
}

///
/// Any property that wants to participate in animations needs to have its type conform
/// to this protocol so that it can tell the animation system how to apply its changes.
/// Any custom conformances to this protocol should be as efficient as possible in order
/// to maintain smooth animations.
///
public protocol AnimatableViewProperty: AnimatableViewPropertySetter {

  ///
  /// Implementations should use the `easing` enum's `calculateFrom` method to do the
  /// actual updates, and should merely be passing through the relevant properties.  The
  /// main task of an implementation of this function is to map `oldValue` and
  /// `newValue` to Double in a way that makes sense for their type.  For example, a
  /// Colour would pass through the red, green, blue, and alpha values as Doubles.
  ///
  mutating func update(with easing: Easing,
                       currentFrame: Double,
                       oldValue: Self,
                       newValue: Self,
                       duration: Double)

  mutating func write(to view: View, at path: ReferenceWritableKeyPath<View, Self>)
}

public protocol AnimatableViewPropertySetter {

  ///
  /// Called by the animation system in order to update the property's value.  It's
  /// the implementor's responsibility to cast `value` to the expected type, returning
  /// false if it fails.
  ///
  mutating func forwardingUpdate(with easing: Easing,
                                 currentFrame: Double,
                                 oldValue: Any,
                                 newValue: Any,
                                 duration: Double) -> Bool

  func forwardingWrite<Container: Animatable>(to view: Container, at path: PartialKeyPath<Container>)
}

extension AnimatableViewProperty {
  public func forwardingWrite<Container: Animatable>(to view: Container,
                                                     at path: PartialKeyPath<Container>) {
    if let path = path as? ReferenceWritableKeyPath<Container, Self> {
      write(to: view, at: path)
    }
  }

  public func write<Container: Animatable>(to view: Container, at path: ReferenceWritableKeyPath<Container, Self>) {
    view[keyPath: path] = self
  }


  mutating public func forwardingUpdate(with easing: Easing,
                                        currentFrame: Double,
                                        oldValue: Any,
                                        newValue: Any,
                                        duration: Double) -> Bool {
    if let oldValue = oldValue as? Self,
      let newValue = newValue as? Self
    {
      update(with: easing,
             currentFrame: currentFrame,
             oldValue: oldValue,
             newValue: newValue,
             duration: duration)
      return true
    }

    return false
  }
}

///
/// Colour changes can be animated.
///
extension Colour: AnimatableViewProperty {

  ///
  /// Update a colour's RGBA values.
  ///
  public mutating func update(with easing: Easing,
                              currentFrame: Double,
                              oldValue: Colour,
                              newValue: Colour,
                              duration: Double) {

    if oldValue == newValue { return }

    if oldValue.redValue != newValue.redValue {
      redValue.update(with: easing,
                      currentFrame: currentFrame,
                      oldValue: oldValue.redValue,
                      newValue: newValue.redValue - oldValue.redValue,
                      duration: duration)
    }

    if oldValue.greenValue != newValue.greenValue {
      greenValue.update(with: easing,
                        currentFrame: currentFrame,
                        oldValue: oldValue.greenValue,
                        newValue: newValue.greenValue - oldValue.greenValue,
                        duration: duration)
    }

    if oldValue.blueValue != newValue.blueValue {
      blueValue.update(with: easing,
                       currentFrame: currentFrame,
                       oldValue: oldValue.blueValue,
                       newValue: newValue.blueValue - oldValue.blueValue,
                       duration: duration)
    }

    if oldValue.alphaValue != newValue.alphaValue {
      alphaValue.update(with: easing,
                        currentFrame: currentFrame,
                        oldValue: oldValue.alphaValue,
                        newValue: newValue.alphaValue - oldValue.alphaValue,
                        duration: duration)
    }
  }
}

///
/// Doubles can be animated.
///
extension Double: AnimatableViewProperty {

  ///
  /// Ease from the old value to the new.
  ///
  public mutating func update(with easing: Easing,
                              currentFrame: Double,
                              oldValue: Double,
                              newValue: Double,
                              duration: Double) {
    if oldValue == newValue { return }

    self = easing.calculateFrom(currentFrame: currentFrame,
                                startValue: oldValue,
                                totalChange: newValue - oldValue,
                                totalFrames: duration)
  }
}

///
/// CGFloats can be animated.
///
extension CGFloat: AnimatableViewProperty {

  ///
  /// Ease from the old value to the new.
  ///
  public mutating func update(with easing: Easing,
                              currentFrame: Double,
                              oldValue: CGFloat,
                              newValue: CGFloat,
                              duration: Double) {
    if oldValue == newValue { return }

    let result = easing.calculateFrom(currentFrame: currentFrame,
                                      startValue: Double(oldValue),
                                      totalChange: Double(newValue - oldValue),
                                      totalFrames: duration)
    self = CGFloat(result)
  }
}

///
/// Ints can be animated.
///
extension Int: AnimatableViewProperty {

  ///
  /// Ease from the old value to the new.
  ///
  public mutating func update(with easing: Easing,
                              currentFrame: Double,
                              oldValue: Int,
                              newValue: Int,
                              duration: Double) {
    if oldValue == newValue { return }

    let result = easing.calculateFrom(currentFrame: currentFrame,
                                      startValue: Double(oldValue),
                                      totalChange: Double(newValue - oldValue),
                                      totalFrames: duration)
    self = Int(result)
  }
}


///
/// Adds animation support to Yoga LayoutValues.
///
extension LayoutValue: AnimatableViewProperty {
  public mutating func update(with easing: Easing,
                              currentFrame: Double,
                              oldValue: LayoutValue,
                              newValue: LayoutValue,
                              duration: Double) {
    if oldValue.value == newValue.value { return }

    let value = easing.calculateFrom(currentFrame: currentFrame,
                                     startValue: Double(oldValue.value),
                                     totalChange: Double(newValue.value - oldValue.value),
                                     totalFrames: duration)

    self = LayoutValue(unit: self.unit, value: Float(value))
  }
}

extension Font: AnimatableViewProperty {

  mutating public func update(with easing: Easing,
                              currentFrame: Double,
                              oldValue: Font,
                              newValue: Font,
                              duration: Double) {
    if oldValue.size == newValue.size { return }

    let value = easing.calculateFrom(currentFrame: currentFrame,
                                     startValue: Double(oldValue.size),
                                     totalChange: Double(newValue.size - oldValue.size),
                                     totalFrames: duration)
    self.size = value
  }
}
