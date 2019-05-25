//
//  CGRect.swift
//  Suit
//
//  Created by pmacro  on 18/02/2019.
//

import Foundation

extension Array where Element == CGRect {
  
  func union() -> CGRect? {
    guard let first = self.first else { return nil }
    
    if count == 1 { return first }
    
    var joined = first
    
    for i in 1..<count {
      joined = joined.union(self[i])
    }
    
    return joined
  }
  
}
