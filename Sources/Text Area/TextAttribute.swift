//
//  TextAttribute.swift
//  Suit
//
//  Created by pmacro  on 08/02/2019.
//

import Foundation

public typealias UTF8Offset = Int

extension TextAttribute: DocumentMarker {
  public func copy() -> Self {
    return type(of: self).init(color: color, range: range)
  }
}

public class TextAttribute {
  let color: Color
  
  /// The range of the text attribute, in UTF8 code points.
  public var range: Range<UTF8Offset> {
    didSet {
      #if os(macOS) || os(iOS)
      utf16Range = nil
      #endif
    }
  }
  
  #if os(macOS) || os(iOS)
  var utf16Range: NSRange?
  #endif
  
  required public init(color: Color, range: Range<UTF8Offset>) {
    self.color = color
    self.range = range
  }
  
  #if os(macOS) || os(iOS)
  func createUTF16Range(using string: String) -> NSRange? {
    guard range.lowerBound >= 0 else { return nil }
    
    if let utf16Range = utf16Range { return utf16Range }
    
    let startIdx = string.utf8.startIndex
    
    guard let start = string.utf8.index(startIdx,
                                  offsetBy: range.lowerBound,
                                  limitedBy: string.endIndex),
          let end = string.utf8.index(start,
                                      offsetBy: range.count,
                                      limitedBy: string.endIndex),
          let utf16Start = String.Index(start, within: string.utf16),
          let utf16End = String.Index(end, within: string.utf16) else
    {
      return nil
    }
    
    utf16Range = NSRange(utf16Start..<utf16End, in: string)
    return utf16Range
  }
  #endif
}
