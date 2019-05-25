//
//  KeyEventDelegate.swift
//  Suit
//
//  Created by pmacro on 18/06/2018.
//

import Foundation

public protocol KeyEventDelegate {  
  func onKeyEvent(_ keyEvent: KeyEvent) -> Bool
}
