//
// Created by pmacro on 14/01/17.
//

import Foundation

public enum HorizontalTextArrangement {
  case center
  case left
  case right
}

public enum VerticalTextArrangement {
  case center
  case top
  case bottom
}


protocol TextDisplay {
  var font: Font { set get }
  var horizontalArrangement: HorizontalTextArrangement { set get }
  var verticalArrangement: VerticalTextArrangement { set get }
}
