//
// Created by pmacro on 28/01/2017.
//

import Foundation

func +(lhs: EdgeInsets, rhs: EdgeInsets) -> EdgeInsets {
  return EdgeInsets(left: lhs.left + rhs.left,
                    right: lhs.right + rhs.right,
                    top: lhs.top + rhs.top,
                    bottom: lhs.bottom + rhs.bottom)
}

public struct EdgeInsets {
  let left: CGFloat
  let right: CGFloat
  let top: CGFloat
  let bottom: CGFloat

  public init(left: CGFloat, right: CGFloat, top: CGFloat, bottom: CGFloat) {
    self.left = left
    self.right = right
    self.top = top
    self.bottom = bottom
  }
}
