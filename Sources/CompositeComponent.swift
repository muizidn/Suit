//
//  CompositeComponent.swift
//  Suit
//
//  Created by pmacro on 11/06/2018.
//

import Foundation

///
/// A composite component is one that can be made up of other components.  In most cases,
/// this is the preferred component to use since it offers much greater flexibility
/// and more granular composition of UIs.
///
open class CompositeComponent: Component {
  
  /// The components that make up this composite component.
  open var components: [Component] = []

  ///
  /// Prepares the view and this component's child components.
  ///
  open override func viewDidLoad() {
    super.viewDidLoad()
    prepareChildComponents()
  }
  
  ///
  /// Prepares the child components and adds their view's to this component's views.
  ///
  func prepareChildComponents() {
    for view in view.subviews where components.contains(where: { $0.view == view }) {
      view.removeFromSuperview()
    }

    for component in components {
      prepare(childComponent: component)
    }
  }
  
  ///
  /// Prepare a child component for use.
  ///
  func prepare(childComponent: Component) {
    configure(child: childComponent)
    view.add(subview: childComponent.view)
  }
  
  ///
  /// Configures a child component for use within this composite component, without
  /// adding its view.
  ///
  open func configure(child: Component) {
    if !child.isLoaded {
      load(component: child)
      child.viewDidLoad()
    }
  
    child.wasConfiguredAsChildComponent()
  }
  
  ///
  /// Adds a component to this composite component, inserting it's view into the root view.
  ///
  open func add(component: Component) {
    component.parentComponent = self
    components.append(component)
    
    if isLoaded {
      prepare(childComponent: component)
    }
    
    component.updateAppearance(style: Appearance.current)
    Appearance.updateAppearance(onView: component.view)
  }
  
  ///
  /// Remove the component from this component.  This also remove the component's view.
  ///
  open func remove(component: Component) {
    component.parentComponent = nil
    components.removeAll { $0 == component }
    component.view.removeFromSuperview()
  }
  
  ///
  /// Removes all child components except the one provided as a parameter.
  ///
  open func removeAllExcept(component: Component) {
    var removedIndices = [Int]()
    for child in components {
      if child != component {
        child.parentComponent = nil
        child.view.removeFromSuperview()
        
        if let idx = components.firstIndex(of: child) {
          removedIndices.append(idx)
        }
      }
    }
    
    let indices = removedIndices.sorted().reversed()
    
    for index in indices {
      components.remove(at: index)
    }
  }
  
  open override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    components.forEach {
      $0.updateAppearance(style: style)
    }
  }
}
