//
//  ViewHelpers.swift
//  SuitTestUtils
//
//  Created by pmacro  on 28/02/2019.
//

import Foundation
import Suit

public func createView<T: View>(ofType type: T.Type) -> T {
  let view = type.init()
  view.window = window
  view.draw()
  return view
}
