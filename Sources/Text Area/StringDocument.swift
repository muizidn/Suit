//
//  StringDocument.swift
//  Suit
//
//  Created by pmacro  on 22/02/2019.
//

import Foundation

/// DELETE ME once we switch to Swift 5.1.
extension String {
  var isNativeUTF8: Bool {
    return utf8.withContiguousStorageIfAvailable { _ in 0 } != nil
  }

  mutating func makeNativeUTF8IfNeeded() {
    if !isNativeUTF8 {
      self += ""
    }
  }
}

///
/// A StringDocument is the backing storage for a TextAreaView's contents.  It provides
/// efficent access to the string and information about that string, such as line
/// information.
///
open class StringDocument: ExpressibleByStringLiteral {

  /// The document's contents.  Note that you should not try to modify this value
  /// directly in anyway.
  public private(set) var buffer: String = ""

  /// The number of lines in the document.  This number is kept up-to-date as the
  /// document changes.
  public private(set) var numberOfLines = 0
  
  /// The range of characters on each line, in UTF8 terms.  The ranges are
  /// within the whole document (as opposed to starting a 0 on each line).
  /// You can access the range of a particular line by calling:
  /// lineCharacterRanges[lineNumber - 1]
  public var lineCharacterRanges = [Range<UTF8Offset>]()

  /// A cache of the document's line ranges.  The ranges can be accessed using
  /// a zero-based line number as the key.  These ranges are lazily
  /// cached into this variable, and the contents are cleared when the
  /// document changes.
  var lineRangesCache = [Int : Range<String.Index>]()

  /// The start startIndex of `buffer`.
  public var startIndex: String.Index {
    return buffer.startIndex
  }

  /// The start endIndex of `buffer`.
  public var endIndex: String.Index {
    return buffer.endIndex
  }

  /// `buffer`'s startIndex..<endIndex.
  public var range: Range<String.Index> {
    return buffer.startIndex..<buffer.endIndex
  }

  /// Is the document empty?
  public var isEmpty: Bool {
    return buffer.isEmpty
  }

  /// The number of characters in this document.
  public var count: Int {
    return buffer.count
  }

  /// The textAttributes for the document.  If you set this property StringDocument will
  /// react accordingly, but if you modify it, please call didUpdateTextAttributes() in
  /// order to update the internal state.
  public var textAttributes: [TextAttribute]?
  {
    didSet {
      textAttributes?.sort(by: { (lhs, rhs) -> Bool in
        return lhs.range.lowerBound < rhs.range.lowerBound
      })
      recalculateAttributesByLine()
    }
  }

  /// It's not ergonomic for the user to supply attributes by line, but it's much more
  /// efficient to use them in that format, so we maintain a second array of text
  /// attributes arranged by line.
  var textAttributesByLine = [[TextAttribute]?]()

  /// The document markers for this document.
  public var documentMarkers: [TextDocumentMarker]?
  {
    didSet {
      recalculateMarkersByLine()
    }
  }

  /// The document markers arranged by line.
  var documentMarkersByLine = [[TextDocumentMarker]?]()

  ///
  /// Instantiates a StringDocument from a string literal.
  ///
  public required init(stringLiteral value: String) {
    buffer = value
    recalculateState()
  }

  public convenience init(string: String) {
    self.init(stringLiteral: string)
  }

  ///
  /// For a given line number, this function returns the *UTF8* indices of the
  /// line's contents within the whole document.
  ///
  /// The results of this function are cached internally such that calling this method
  /// multiple times for the same line number will not result in repeat calculation of
  /// the indices, unless the document's contents change in between calls.
  ///
  /// - parameter lineNumber: the line number within the range 1...numberOfLines.
  ///
  /// - returns: the UTF8 index range for the line.
  ///
  public func rangeOfLine(_ lineNumber: Int) -> Range<String.Index>? {
    if let range = lineRangesCache[lineNumber - 1] {
      return range
    }

    if let utf8Range = lineCharacterRanges[safe: lineNumber - 1] {
      let lower = buffer.utf8.index(startIndex, offsetBy: utf8Range.lowerBound)
      let upper = buffer.utf8.index(lower, offsetBy: utf8Range.count)

      let range = lower..<upper

      lineRangesCache[lineNumber - 1] = range
      return range
    }

    return nil
  }

  ///
  /// Recalculate the state from scratch, throwing away any caches.
  ///
  func recalculateState() {
    lineCharacterRanges = calculateUTF8LineRanges()
    lineRangesCache = [:]
    numberOfLines = lineCharacterRanges.count
    recalculateAttributesByLine()
  }

  ///
  /// Calculates the UTF8 ranges of each line in the document.
  ///
  func calculateUTF8LineRanges() -> [Range<Int>] {
    let lineFeed = 0x0A
    let carriageReturn = 0x0D
    let lfcr = 0x0A0D
    
    #if swift(>=5.1)
    print("Swift 5.1 is being used.  Switch to using buffer.withUTF8")
    #endif
    
    buffer.makeNativeUTF8IfNeeded()

    // FIXME TODO!!  Switch to buffer.withUTF8 once Swift 5.1 is available as this can fail.
    //

    return buffer.utf8.withContiguousStorageIfAvailable {
      (pointer: UnsafeBufferPointer<UInt8>) -> [Range<Int>] in
      var ranges = [Range<Int>]()
      var startIdx = 0
      var currentIdx = 0

      for char in pointer {
        currentIdx += 1

        if char == lineFeed || char == carriageReturn || char == lfcr {
          ranges.append(startIdx..<currentIdx)
          startIdx = currentIdx
        }
      }

      // Special case for the last line.
      if let last = pointer.last, last == lineFeed {
        ranges.append(currentIdx..<currentIdx)
      } else {
        ranges.append(startIdx..<currentIdx)
      }

      return ranges
      }  ?? []
  }

  ///
  /// Converts an array of UTF8 ranges to String index ranges.  The result is still
  /// UTF8 based.
  ///
  func calculateLineIndicesFromUTF8LineRanges(_ utf8LineRanges: [Range<UTF8Offset>]) -> [Range<String.Index>] {
    let lineCount = utf8LineRanges.count

    var lineRanges = [Range<String.Index>]()

    var previousLineEndIdx: String.Index?

    for i in 0..<lineCount {
      let start = previousLineEndIdx ?? buffer.utf8.startIndex

      let lineCharRanges = utf8LineRanges[i]
      let length = lineCharRanges.count

      let idx = buffer.utf8.index(start, offsetBy: length)

      let lineIndexRange = start..<idx
      lineRanges.append(lineIndexRange)

      previousLineEndIdx = idx
    }

    return lineRanges
  }

  ///
  /// Inserts a string into the document.  Calling this method updates all elements of
  /// the document to reflect the update, such as line numbers, line ranges etc.
  ///
  public func insert(_ string: String, at position: String.Index) {
    let isEmptyOrSingleLine = buffer.isEmpty || numberOfLines < 2

    buffer.insert(contentsOf: string, at: position)

    if isEmptyOrSingleLine {
      recalculateState()
      return
    }

    if string.contains("\n") {
      // TODO fix this.  Blowing everything away for now.
      recalculateState()
    } else {
      let utf8Count = string.utf8.count

      guard let utf8Index = position.samePosition(in: buffer.utf8) else {
        recalculateState()
        return
      }

      let offset = buffer.utf8.distance(from: startIndex, to: utf8Index)

      guard let lineIndex = lineCharacterRanges.binarySearch(key: offset..<offset + 1) else {
        recalculateState()
        return
      }

      // Update the line range for the line that was actually edited.
      //
      let lineRange = lineCharacterRanges[lineIndex]
      lineCharacterRanges[lineIndex] = lineRange.lowerBound..<lineRange.upperBound + utf8Count
      lineRangesCache[lineIndex] = nil

      // Update the attributes for the line that was edited.
      // lineAttributes are zero-based to the start of the line, so only the
      // edited line is affected.
      if let temp = textAttributesByLine[safe: lineIndex], let attributes = temp {
        let start = offset - lineRange.lowerBound
        let end = start + utf8Count
        let editRange = start..<end

        for marker in attributes {
          marker.reactToEdit(at: editRange,
                             in: self,
                             isDeletion: false)
        }
      }

      // Now, update all the lines AFTER the edit.
      //
      for lineIndex in (lineIndex + 1)..<numberOfLines {
        let lineRange = lineCharacterRanges[lineIndex]
        // Update affected line utf8 character ranges.
        lineCharacterRanges[lineIndex] = lineRange.lowerBound + utf8Count
          ..<
          lineRange.upperBound + utf8Count

        // Invalidate affected line indices.
        lineRangesCache[lineIndex] = nil
      }
    }
  }

  ///
  /// Removes a content from the document.  Calling this method updates all elements of
  /// the document to reflect the update, such as line numbers, line ranges etc.
  ///
  /// - parameter index: the index at the start of the deletion.
  /// - parameter count: the number of characters to delete.
  ///
  public func remove(at index: String.Index, count: Int = 1) {
    let deletionRange = index..<buffer.index(index, offsetBy: count)
    remove(range: deletionRange)
  }

  ///
  /// Removes a content from the document.  Calling this method updates all elements of
  /// the document to reflect the update, such as line numbers, line ranges etc.
  ///
  /// - parameter range: the range of characters to delete.
  ///
  public func remove(range: Range<String.Index>) {
    let hasNewLines = buffer[range].contains("\n")
    buffer.removeSubrange(range)

    if hasNewLines {
      recalculateState()
    } else {

      guard let utf8Index = range.lowerBound.samePosition(in: buffer.utf8),
        let utf8EndIndex = range.upperBound.samePosition(in: buffer.utf8) else {
          recalculateState()
          return
      }

      let offset = buffer.utf8.distance(from: startIndex, to: utf8Index)

      guard let lineIndex = lineCharacterRanges.binarySearch(key: offset..<offset + 1) else {
        recalculateState()
        return
      }

      let utf8Count = buffer.utf8.distance(from: utf8Index, to: utf8EndIndex)

      // Update the line range for the line that was actually edited.
      //
      let lineRange = lineCharacterRanges[lineIndex]
      lineCharacterRanges[lineIndex] = lineRange.lowerBound..<lineRange.upperBound - utf8Count
      lineRangesCache[lineIndex] = nil

      // Update the attributes for the line that was actually edited.
      //
      if let temp = textAttributesByLine[safe: lineIndex], let attributes = temp {
        let start = offset - lineRange.lowerBound
        let end = start + utf8Count
        let editRange = start..<end

        for marker in attributes {
          marker.reactToEdit(at: editRange,
                             in: self,
                             isDeletion: true)
        }
      }

      // Now, update all the lines AFTER the edit.
      //
      for lineIndex in (lineIndex + 1)..<numberOfLines {
        let lineRange = lineCharacterRanges[lineIndex]
        // Update affected line utf8 character ranges.
        lineCharacterRanges[lineIndex] = lineRange.lowerBound - utf8Count
          ..<
          lineRange.upperBound - utf8Count

        // Invalidate affected line indices.
        lineRangesCache[lineIndex] = nil
      }
    }
  }

  ///
  /// Populates the `documentMarkersByLine` variable with the contents of
  /// `documentMarkers`, separated by line, and adjusted to reference line ranges
  /// rather than document ranges.
  ///
  func recalculateMarkersByLine() {
    if let documentMarkers = documentMarkers {
      recalculateMarkersByLine(source: documentMarkers,
                               target: &documentMarkersByLine)
    } else {
      documentMarkersByLine.removeAll(keepingCapacity: true)
    }
  }

  ///
  /// Populates the `target` variable with the contents of
  /// `source`, separated by line, and adjusted to reference line ranges
  /// rather than document ranges.
  ///
  func recalculateMarkersByLine<T: DocumentMarker>(source: [T],
                                                   target: inout [[T]?]) {
    if !target.isEmpty {
      target.removeAll(keepingCapacity: true)
    }

    guard source.isEmpty == false else {
      return
    }

    for lineRange in lineCharacterRanges {
      let adjustedAttributes = source.in(range: lineRange) ?? []
      let result = Array(adjustedAttributes).adjustedBy(offset: -lineRange.lowerBound)
      target.append(result)
    }
  }

  ///
  /// Call this method whenever you manipulate `textAttributes`.  You do not need to
  /// call this if you set `textAttributes` to a new value.
  ///
  public func didUpdateTextAttributes() {
    recalculateAttributesByLine()
  }
  
  ///
  /// Populates the `textAttributesByLine` variable with the contents of
  /// `textAttributes`, separated by line, and adjusted to reference line ranges
  /// rather than document ranges.
  ///
  func recalculateAttributesByLine() {
    if let textAttributes = textAttributes {
      recalculateMarkersByLine(source: textAttributes,
                               target: &textAttributesByLine)
    } else {
      textAttributesByLine.removeAll(keepingCapacity: true)
    }
  }

  ///
  /// Finds all occurances of `searchTerm`, to a maximum of `limit` (a nil limit
  /// means unlimited), and returns the index ranges of the matching text.
  ///
  public func find(searchTerm: String, limit: Int? = nil) -> [Range<String.Index>] {
    var searchRange = range
    var results = [Range<String.Index>]()
    var resultsCount = 0

    while let result = buffer.range(of: searchTerm,
                                    options: .regularExpression,
                                    range: searchRange) {
                                      results.append(result)
                                      resultsCount += 1

                                      if let limit = limit, resultsCount >= limit {
                                        break
                                      }

                                      if result.upperBound < endIndex {
                                        searchRange = result.upperBound..<endIndex
                                      } else {
                                        break
                                      }
    }

    return results
  }

  ///
  /// Finds all document markers within the given range.
  ///
  public func rangesOfMarkers(within range: Range<String.Index>) -> [DocumentMarker] {
    var searchRange = range
    var results = [TextDocumentMarker]()

    while let result = buffer.range(of: #"\$\{.*?\}"#,
                                    options: .regularExpression,
                                    range: searchRange) {

      guard let utf8Start = String.Index(result.lowerBound, within: buffer.utf8),
        let utf8End = String.Index(result.upperBound, within: buffer.utf8) else {
          // This should never happen...
          continue
      }

      let start = buffer.utf8.distance(from: buffer.utf8.startIndex, to: utf8Start)
      let length = buffer.utf8.distance(from: utf8Start, to: utf8End)

      results.append(TextDocumentMarker(range: start..<start + length))

      if result.upperBound < searchRange.upperBound {
        searchRange = result.upperBound..<searchRange.upperBound
      } else {
        break
      }
    }

    return results
  }

  ///
  /// Finds the first non-whitespace character index past the provided index.
  ///
  public func indexAfterWhitespace(startingAt index: String.Index) -> String.Index {
    if index == endIndex { return index }

    var idx = self.index(after: index)

    while distance(from: idx, to: endIndex) > 0 {
      let char = self[idx]
      if char == " " || char == "\n" {
        return idx
      }

      idx = self.index(after: idx)

      if idx == buffer.index(before: endIndex) { return idx }
    }

    return idx
  }

  ///
  /// Finds the first non-whitespace character index before the provided index.
  ///
  public func indexBeforeWhitespace(startingAt index: String.Index) -> String.Index {
    if index == startIndex { return index }

    var idx = self.index(before: index)
    var metNonWhitespace = false

    while distance(from: startIndex, to: idx) > 0 {
      let char = self[idx]
      if metNonWhitespace && (char == " " || char == "\n") {
        return self.index(after: idx)
      }

      metNonWhitespace = true
      idx = self.index(before: idx)
    }

    return idx
  }
  
  ///
  /// Finds the first occurence of `character` starting at `index` and searching in
  /// the provided direction.
  ///
  public func index(of character: Character,
                    startingAt index: String.Index,
                    searchDirection: SearchDirection) -> String.Index? {

    if searchDirection == .left, index == startIndex { return index }
    if searchDirection == .right, index == endIndex { return index }

    let mover: (String.Index) -> String.Index?

    if searchDirection == .left {
      mover = { [weak self] current in
        guard let `self` = self else { return nil }
        if current > self.startIndex {
          return self.buffer.index(before: current)
        }
        return nil
      }
    } else {
      mover = { [weak self] current in
        guard let `self` = self else { return nil }

        if current < self.endIndex {
          return self.buffer.index(after: current)
        }
        return nil
      }
    }

    var currentIndex: String.Index? = min(index, self.index(before: endIndex))

    while let idx = currentIndex {
      if buffer[idx] == character {
        return idx
      }

      currentIndex = mover(idx)
    }

    return nil
  }
}

///
/// A set of shortcuts for common methods.
///
extension StringDocument {
  subscript(_ range: Range<String.Index>) -> Substring {
    return buffer[range.clamped(to: buffer.startIndex..<buffer.endIndex)]
  }
  
  subscript(_ index: String.Index) -> Character {
    return buffer[index]
  }
  
  public func distance(from: String.Index, to: String.Index) -> Int {
    if from > to {
      let range = (to..<from).clamped(to: startIndex..<endIndex)
      return -buffer.distance(from: range.lowerBound, to: range.upperBound)
    }
    
    let range = (from..<to).clamped(to: startIndex..<endIndex)
    return buffer.distance(from: range.lowerBound, to: range.upperBound)
  }
  
  public func index(after index: String.Index) -> String.Index {
    return buffer.index(after: index)
  }
  
  public func index(before index: String.Index) -> String.Index {
    return buffer.index(before: index)
  }
  
  public func index(_ index: String.Index, offsetBy offset: Int) -> String.Index {
    return buffer.index(index, offsetBy: offset)
  }
  
  public func removeSubrange(_ range: Range<String.Index>) {
    remove(range: range)
  }
}
