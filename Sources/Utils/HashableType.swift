//
//  HashableType.swift
//  Suit
//
//  Created by pmacro  on 19/03/2019.
//

import Foundation

struct HashableType<T> : Hashable {
  
  static func == (lhs: HashableType, rhs: HashableType) -> Bool {
    return lhs.base == rhs.base
  }
  
  let base: T.Type
  
  init(_ base: T.Type) {
    self.base = base
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(base))
  }
}
