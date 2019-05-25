//
//  Appearance.swift
//  Suit
//
//  Created by pmacro on 15/06/2018.
//

import Foundation

///
/// A style of appearance for an application.
///
public enum AppearanceStyle: Int, Codable {
  case dark
  case light
}

///
/// Manages the current appearance style.  Use the static `current` variable to access
/// and to alter the active style.
///
public class Appearance {
  
  /// The active appearance style.  Changing this value triggers updateAppearance calls
  /// on all views and components.  Custom views and components should be sure to implement
  /// appropriate styling changes inside updateAppearance methods.
  public static var current: AppearanceStyle = .light {
    didSet {
      refresh()
    }
  }

  internal static func refresh() {
    // If no app exists yet, we don't need to worry about updating it.
    if Application.instance == nil { return }


    for window in Application.shared.windows {
      refresh(window: window)
    }
  }

  internal static func refresh(window: Window) {
    updateAppearance(onView: window.rootView)
    window.rootComponent.updateAppearance(style: current)
    window.redrawManager.redraw(view: window.rootView)
  }

  static func updateAppearance(onView view: View) {
    view.updateAppearance(style: current)
    view.subviews.forEach {
      updateAppearance(onView: $0)
    }
  }
}

public protocol AppearanceAdoption {
  func updateAppearance(style: AppearanceStyle)
}
