//
//  DocumentMarker.swift
//  Suit
//
//  Created by pmacro on 18/04/2019.
//

import Foundation

///
/// A document marker marks a range within a document.  It can move within the document
/// as the document is edited.  Typically a document marker is used to associate a piece
/// of information with a range of text.
///
public protocol DocumentMarker: class {
  var range: Range<UTF8Offset> { get set }
  func adjust(by offset: UTF8Offset)
  func copy() -> Self
}

///
/// A document marker for a text document.  This class stores only a range
/// and should be subclassed in order to persist information alongside the marker.
///
public class TextDocumentMarker: DocumentMarker {
  public var range: Range<UTF8Offset>
  
  required public init(range: Range<UTF8Offset>) {
    self.range = range
  }
  
  public func copy() -> Self {
    return type(of: self).init(range: range)
  }
}

///
/// Functions for updating a marker in response to the editing of the document
/// to which it belongs.
///
extension DocumentMarker {
  
  ///
  /// Adjusts the marker's lower and upper bounds by the supplied offset.  The
  /// provided offset can be positive or negative.
  ///
  public func adjust(by offset: UTF8Offset) {
    range = range.lowerBound + offset..<range.upperBound + offset
  }

  ///
  /// Moves a marker according to the edited range.
  ///
  func reactToEdit(at editRange: Range<Int>,
                   in document: StringDocument,
                   isDeletion: Bool) {
    // Doesn't affect us.
    if editRange.lowerBound > range.upperBound
      // We generally want to skip the case where the marker's upperBound touches the lowerBound of the
      // edit, but not when this is the end of the document.
      || (editRange.lowerBound == range.upperBound
        && editRange.upperBound != document.buffer.utf8.count ) {
      return
    }
    
    var editLength = editRange.count
    editLength = isDeletion ? -editLength : editLength
    let utf8Count = document.buffer.utf8.count
    
    // Simple matter of moving the marker by the edited amount.
    if editRange.lowerBound < range.lowerBound {
      let newLowerBound = range.lowerBound < utf8Count
        ? range.lowerBound + editLength
        : range.lowerBound
      
      let newUpperBound = range.upperBound < utf8Count
        ? range.upperBound + editLength
        : range.upperBound
      
      range = (newLowerBound..<newUpperBound).clamped(to: 0..<utf8Count)
      return
    }
    
    // We're part of the edit.
    let newLowerBound = isDeletion
      ? min(range.lowerBound, editRange.lowerBound)
      : range.lowerBound
    
    let newUpperBound = range.upperBound + editLength
    
    if newLowerBound < newUpperBound {
      range = newLowerBound..<newUpperBound
    }
    else {
      range = newUpperBound..<newLowerBound
    }
    
    return
  }
}

///
/// Functions for slicing document marker arrays.
///
extension Array where Element: DocumentMarker {
  func `in`(range: Range<UTF8Offset>) -> ArraySlice<Element>? {
    if range.isEmpty { return [] }
    
    var firstLowerBound = binarySearch(index: range.upperBound - 1)
    
    // Binary search is fast and therefore worth using, but it doesn't guarantee that
    // the first of a set of duplicates is returned, so we need to manually move to the
    // start of the boundary in that case.
    while let result = firstLowerBound, result > 0 {
      if self[result - 1].range.upperBound >= range.lowerBound {
        firstLowerBound = result - 1
      } else {
        break
      }
    }
    
    guard let start = firstLowerBound else {
      return nil
    }
    
    let attributeCount = count
    var firstUpperBound = binarySearch(index: range.upperBound - 1)
    
    while let result = firstUpperBound, result < attributeCount - 1 {
      if self[result + 1].range.upperBound < range.upperBound {
        firstUpperBound = result + 1
      } else {
        break
      }
    }
    
    let end = firstUpperBound ?? start
    
    let range: Range<Int>
    
    if start < end {
      range = (start..<end + 1)
    } else {
      range = (end..<start + 1)
    }
    
    return self[range.clamped(to: self.startIndex..<self.endIndex)]
  }
}

///
/// Functions for adjusting document marker positions.
///
extension Array where Element: DocumentMarker {
  
  func adjustedBy(offset: Int) -> [Element] {
    var result = [Element]()
    
    for temp in self {
      let attribute = temp.copy()
      
      adjust(attribute, by: offset)
      
      if attribute.range.lowerBound >= 0,
        attribute.range.upperBound >= attribute.range.lowerBound
      {
        result.append(attribute)
      }
    }
    
    return result
  }
  
  func adjust(_ attribute: Element, by offset: Int) {
    attribute.adjust(by: offset)
    
    // If an attribute runs across lines it can be adjusted to be < 0, so we need to chop
    // of the part that was on the previous line, leaving only the part relevant to this
    // line.
    if attribute.range.lowerBound < 0, attribute.range.upperBound > 0 {
      attribute.range = 0..<attribute.range.upperBound
    }
  }
}

///
/// Functionality for collections of DocumentMarkers.
///
extension BidirectionalCollection where Element: DocumentMarker, Index == Int {
  func binarySearch(index: Int, range: ClosedRange<Int>? = nil) -> Int? {
    let searchRange = range ?? startIndex...endIndex
    
    if searchRange.lowerBound >= searchRange.upperBound {
      // If we get here, then the search key is not present in the array,
      // so return the nearest match.
      return searchRange.upperBound
    }
    else {
      // Calculate where to split the array.
      let midIndex = searchRange.lowerBound + (searchRange.upperBound - searchRange.lowerBound) / 2
      let element = self[midIndex]
      
      // Is the search key in the left half?
      if index < element.range.lowerBound {
        return binarySearch(index: index,
                            range: searchRange.lowerBound...midIndex)
        
        // Is the search key in the right half?
      } else if index > element.range.upperBound {
        return binarySearch(index: index,
                            range: midIndex + 1...searchRange.upperBound)
        
        // If we get here, then we've found the search key!
      } else {
        return midIndex
      }
    }
  }
}
