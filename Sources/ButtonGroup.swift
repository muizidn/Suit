//
//  ButtonGroup.swift
//  Suit
//
//  Created by pmacro on 03/04/2019.
//

import Foundation

///
/// A container that manages child Button instances such that only one child button is in a
/// `pressed` state at any given time.
///
public class ButtonGroup: View {
  
  var selectedButtonIndex: Int? {
    didSet {
      if let oldValue = oldValue {
        (subviews[safe: oldValue] as? Button)?.state = .unfocused
      }
      
      if let selectedButtonIndex = selectedButtonIndex {
        (subviews[safe: selectedButtonIndex] as? Button)?.state = .pressed
      }
    }
  }
  
  ///
  /// Adds a button to this button group view.
  ///
  public func add(button: Button) {
    add(subview: button)
    button.prePress = { [weak self] in
      self?.selectedButtonIndex = self?.subviews.firstIndex(of: button)
    }
  }
}
