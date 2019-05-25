//
//  Bundle.swift
//  Suit
//
//  Created by pmacro  on 03/04/2019.
//

import Foundation

extension Bundle {
  
  ///
  /// Retrieves the path of an asset according to the specified name and type.
  ///
  /// - parameter named: the name of the asset to retrieve.
  /// - parameter type: the type of asset to retrieve.
  ///
  /// - returns: the path, or nil if the asset was not found.
  ///
  public func path(forAsset named: String, ofType type: String) -> String? {
    return path(forResource: "Assets/" + named, ofType: type)
  }
}
