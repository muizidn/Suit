//
//  AnimationProperties.swift
//  Suit
//
//  Created by pmacro on 30/04/2019.
//

import Foundation

///
/// The properties on an entity that are animatable and the entity to which those
/// properties belong.
///
struct AnimationProperties<Container: Animatable> {
  
  /// A dictionary of animatable property key paths and the "setter" that can apply
  /// updates to the matching key path.  In other words, you use the setter to apply
  /// updates the key path.
  var propertyValues: [PartialKeyPath<Container> : AnimatableViewPropertySetter] = [:]
  
  /// A non-retained reference to the entity to which these animation properties belong.
  weak var target: Container?
  
  ///
  /// Creates AnimationProperties from a container and the container's key paths,
  /// wrapped up inside AnimatedProperties.
  ///
  init(from view: Container, properties: AnimatableProperties<Container>) {
    self.target = view
    
    for prop in properties.animatablePropertyKeyPaths {
      propertyValues[prop] = view[keyPath: prop] as? AnimatableViewPropertySetter
    }
  }
  
  ///
  /// Applies the animation property values stored within this object to its target object.
  ///
  func apply() {
    guard let target = target else { return }
    
    for propertyValue in propertyValues {
      let setter = propertyValue.value
      setter.forwardingWrite(to: target, at: propertyValue.key)
    }
  }
}
