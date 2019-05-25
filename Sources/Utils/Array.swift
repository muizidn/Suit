//
//  Array.swift
//  Editor
//
//  Created by pmacro  on 29/01/2019.
//

import Foundation

extension Collection {
  
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  public subscript (safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

extension Array where Element == Range<String.Index> {
  
  func binarySearch(index: String.Index, range: ClosedRange<Int>? = nil) -> Int? {
    let searchRange = range ?? startIndex...endIndex

    if searchRange.lowerBound >= searchRange.upperBound {
      // If we get here, then the search key is not present in the array.
      return nil
    }
    else {
      // Calculate where to split the array.
      let midIndex = searchRange.lowerBound + (searchRange.upperBound - searchRange.lowerBound) / 2
      let element = self[midIndex]
      
      if element.contains(index) {
        return midIndex
      }
      
      // Is the search key in the left half?
      if index < element.lowerBound {
        return binarySearch(index: index,
                            range: searchRange.lowerBound...midIndex)
        
        // Is the search key in the right half?
      } else if index > element.lowerBound {
        return binarySearch(index: index,
                            range: midIndex + 1...searchRange.upperBound)
        
        // If we get here, then we've found the search key!
      } else {
        return midIndex
      }
    }
  }
}

extension Array where Element: Comparable {

  typealias LessThan = (Element, Element) -> Bool
  typealias GreaterThan = (Element, Element) -> Bool
  
  func binarySearch(key: Element,
                    range: ClosedRange<Int>? = nil,
                    lessThan: LessThan = (<),
                    greaterThan: GreaterThan = (>)) -> Int? {
    
    let searchRange = range ?? startIndex...endIndex
    
    if searchRange.lowerBound >= searchRange.upperBound {
      // If we get here, then the search key is not present in the array.
      return nil
      
    } else {
      // Calculate where to split the array.
      let midIndex = searchRange.lowerBound + (searchRange.upperBound - searchRange.lowerBound) / 2
      let element = self[midIndex]
      
      // Is the search key in the left half?
      if lessThan(key, element) {
        return binarySearch(key: key,
                            range: searchRange.lowerBound...midIndex,
                            lessThan: lessThan,
                            greaterThan: greaterThan)
        
        // Is the search key in the right half?
      } else if greaterThan(key, element) {
        return binarySearch(key: key,
                            range: midIndex + 1...searchRange.upperBound,
                            lessThan: lessThan,
                            greaterThan: greaterThan)
        
        // If we get here, then we've found the search key!
      } else {
        return midIndex
      }
    }
  }
}

extension ClosedRange: Comparable {
  public static func < (lhs: ClosedRange<Bound>, rhs: ClosedRange<Bound>) -> Bool {
    return lhs.lowerBound < rhs.lowerBound && lhs.upperBound < rhs.upperBound
  }
}

extension Range: Comparable {
  public static func < (lhs: Range<Bound>, rhs: Range<Bound>) -> Bool {
    return lhs.lowerBound < rhs.lowerBound && lhs.upperBound < rhs.upperBound
  }
}
