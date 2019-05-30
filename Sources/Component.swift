//
//  Component.swift
//  Suit
//

import Foundation

///
/// A Component manages the display and layout of one or more views.
///
open class Component: Equatable {
  static var counter = 0
  
  public static func == (lhs: Component, rhs: Component) -> Bool {
    return lhs.identifier == rhs.identifier
  }
  
  /// The component's root view.
  var _view: View?
  
  /// Is the view controller fully loaded, i.e. its viewDidLoad method was called?
  var isLoaded = false
  
  /// The component's root view.
  open var view: View {
    set {
      _view = newValue
    }
    
    get {
      if _view == nil {
        _view = View()
      }
      return _view!
    }
    
  }
  
  /// The component's parent component, if one exists.
  open weak var parentComponent: Component?
  
  /// Has the view been loaded already?
  var isViewLoaded: Bool {
    return _view != nil
  }
  
  let identifier: Int
  
  public init() {
    Component.counter += 1
    identifier = Component.counter
  }
  
  open func loadView() {
    if _view == nil {
      _view = View()
    }
  }
  
  ///
  /// This method is called whenever the component's root view has been loaded.
  /// Subclasses can override this method in order to modify the view hierarchy since
  /// it is guaranteed that `view` has been created by the time this method is called.
  ///
  open func viewDidLoad() {
    isLoaded = true
    _view?.background.color = .backgroundColor
  }
  
  ///
  /// Called whenever this component is added as a child of another component.
  ///
  open func wasConfiguredAsChildComponent() {}
  
  ///
  /// Prepares the component for use.
  ///
  func load(component: Component) {
    component.loadView()
    component.view.window = view.window
  }
  
  open func updateAppearance(style: AppearanceStyle) {}
}
