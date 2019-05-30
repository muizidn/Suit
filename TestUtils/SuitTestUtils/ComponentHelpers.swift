//
//  ComponentHelpers.swift
//  SuitTestUtils
//
//  Created by pmacro  on 28/02/2019.
//

import Foundation
@testable import Suit

public func load(component: Component, in window: Window) {
  component.loadView()
  component.view.window = window
  component.viewDidLoad()
}
