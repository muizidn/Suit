//
//  Font+Pango.swift
//  Suit
//
//  Created by pmacro  on 15/03/2019.
//

#if os(Linux)
import Foundation
import Pango

extension FontWeight {
  var pangoWeight: PangoWeight {
    switch self {
    case .thin:
      return PANGO_WEIGHT_THIN
    case .ultraLight:
      return PANGO_WEIGHT_ULTRALIGHT
    case .light:
      return PANGO_WEIGHT_LIGHT
    case .medium:
      return PANGO_WEIGHT_MEDIUM
    case .bold:
      return PANGO_WEIGHT_BOLD
    default:
      return PANGO_WEIGHT_NORMAL
    }
  }
}
#endif
