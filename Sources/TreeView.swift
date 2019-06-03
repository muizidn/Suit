//
//  TreeView.swift
//  suit
//
//  Created by pmacro on 25/05/2018.
//

import Foundation


protocol TreeViewDelegate {
  func didSelectCell()
}

public class TreeView: View {
  
  open var headerView: View?
  open var footerView: View?

  public var subTreeIndentation: CGFloat = 15
  
  required public init() {
    super.init()
  }
}
