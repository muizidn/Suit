//
//  StringDocumentTests.swift
//  SuitTests
//
//  Created by pmacro  on 22/02/2019.
//

import Foundation

import XCTest
import SuitTestUtils
@testable import Suit

///
/// Tests for the correctness and performance of StringDocument.
///
class StringDocumentTests: XCTestCase {

  ///
  /// Test the count of 'wide' characters is as expected.
  ///
  func testDocumentLength() {
    let doc: StringDocument = "🌎❤️©X"
    XCTAssert(doc.count == 4, "Expected count of 4, got \(doc.count)")
  }
  
  ///
  /// Test the editing of an empty file works as expected.
  ///
  func testEditEmptyFile() {
    let doc: StringDocument = ""
    doc.insert("l", at: doc.startIndex)
    var index = doc.startIndex
    
    index = doc.index(after: index)
    doc.insert("e", at: doc.startIndex)
    index = doc.index(after: index)
    doc.insert("t", at: doc.startIndex)

    XCTAssert(doc.numberOfLines == 1)
    XCTAssert(doc.count == 3)
  }
  
  ///
  /// Test the calculation of the number of lines within an unedited StringDocument.
  ///
  func testLineRangeCalculation() {
    let doc: StringDocument = "hello\nworld"
    XCTAssert(doc.numberOfLines == 2, "Expected 2 lines, found \(doc.numberOfLines)")
  }
  
  ///
  /// Test the calculation of the number of lines within an edited StringDocument.
  ///
  func testLineRangeCalculation2() {
    let doc: StringDocument = "hello\nworld"
    let range = doc.rangeOfLine(2)!
    doc.insert("blah", at: doc.index(range.lowerBound, offsetBy: 3))
    
    XCTAssert(doc.numberOfLines == 2)
    
    let lineRange = doc.rangeOfLine(2)!
    let distance = doc.buffer.distance(from: lineRange.lowerBound, to: lineRange.upperBound)
    XCTAssert(distance == 9, "Expected distance of 9, got \(distance)")
  }
  
  ///
  /// Tests the performance of a editing a large string document.
  ///
  func testLargeDocument() {
    let doc = StringDocument(string: randomString(length: 100000))
    
    let index = doc.buffer.index(doc.startIndex,
                                 offsetBy: 1233)
    
    measure {
      doc.insert("Hello, \nworld", at: index)
    }
  }
  
  func testNewLineInsert() {
    let doc: StringDocument = "hello"
    XCTAssert(doc.numberOfLines == 1, "Expected 1 line, found \(doc.numberOfLines)")
      
    doc.insert("\n", at: doc.endIndex)
    XCTAssert(doc.numberOfLines == 2, "Expected 2 lines, found \(doc.numberOfLines)")
  }
  
  func testDeletion() {
    let doc = StringDocument(string: randomString(length: 1000))
    doc.remove(at: doc.startIndex, count: 500)
    XCTAssert(doc.count == 500)
  }
  
  func testMarkerMovementAfterDeletion() {
    let doc = StringDocument(string: randomString(length: 100000))

    let range = 10000..<20000
    let testMarker = TestMarker(range: range)
    
    let indexOffsetter: ((_ offset: Int) -> String.Index) = { offset in
      doc.index(doc.startIndex, offsetBy: offset)
    }
    
    let startTime = Date()
    
    // Test deleting a middle 2500-length range.
    var deletionRange = indexOffsetter(12500)..<indexOffsetter(15000)
    doc.remove(range: deletionRange)
    testMarker.reactToEdit(at: 12500..<15000, in: doc, isDeletion: true)
    
    XCTAssert(testMarker.range == 10000..<17500)
    
    // Test deleting from the start of the 10000..<17500 range.
    deletionRange = indexOffsetter(10000)..<indexOffsetter(13000)
    doc.remove(range: deletionRange)
    testMarker.reactToEdit(at: 10000..<13000,
                           in: doc,
                           isDeletion: true)
    
    XCTAssert(testMarker.range == 10000..<14500)

    // Test deleting from the end of the 10000..<14500 range.
    deletionRange = indexOffsetter(14000)..<indexOffsetter(14500)
    doc.remove(range: deletionRange)
    testMarker.reactToEdit(at: 14000..<14500,
                           in: doc,
                           isDeletion: true)
    
    XCTAssert(testMarker.range == 10000..<14000)
    
    print("Edit reaction took: \(Date().timeIntervalSince(startTime))s")
  }
  
  func testMarkerMovementAfterInsertion() {
    let doc = StringDocument(string: randomString(length: 100000))
    
    let range = 10000..<20000
    let testMarker = TestMarker(range: range)
        
    // Test adding a middle 2500-length range.
    testMarker.reactToEdit(at: 12500..<15000, in: doc, isDeletion: false)

    print("\(testMarker.range.lowerBound), \(testMarker.range.upperBound)")
    XCTAssert(testMarker.range == 10000..<22500)
    
    // Test adding before the start of the 10000..<22500 range.
    testMarker.reactToEdit(at: 0..<2500, in: doc, isDeletion: false)
    XCTAssert(testMarker.range == 12500..<25000)
    
    // Test adding at the end of the 12500..<25000 range.
    testMarker.reactToEdit(at: 30000..<32500, in: doc, isDeletion: false)
    XCTAssert(testMarker.range == 12500..<25000)
  }
  
  func testMultipleMarkerMovement() {
    let doc = StringDocument(string: randomString(length: 1000))
    
    let range1 = 10..<20
    let range2 = 20..<30
    
    let testMarker1 = TestMarker(range: range1)
    let testMarker2 = TestMarker(range: range2)

    let editRange = 15..<20
    
    testMarker1.reactToEdit(at: editRange, in: doc, isDeletion: false)
    testMarker2.reactToEdit(at: editRange, in: doc, isDeletion: false)

    XCTAssert(testMarker1.range.lowerBound == 10)
    XCTAssert(testMarker1.range.upperBound == 25)
    XCTAssert(testMarker2.range.lowerBound == 25)
    XCTAssert(testMarker2.range.upperBound == 35)
  }
  
  func testLineCountPerformance() {
    let lineCount = 100000
    let doc = StringDocument(string: randomString(numberOfLines: lineCount, lineLength: 100) + "😂")

    measure {
      let _ = doc.calculateUTF8LineRanges()
    }
  }
  
  func testAsciiAndNonAsciiPerformTheSame() {
    let asciiDoc = StringDocument(string: randomString(numberOfLines: 300000,
                                                       lineLength: 100))
    let nonAsciiDoc = StringDocument(string: randomString(numberOfLines: 300000,
                                                          lineLength: 100) + "🏃🏽‍♀️£")
    
    var start = Date()
    asciiDoc.insert("Hello", at: asciiDoc.startIndex)
    let asciiDuration = Date().timeIntervalSince(start)
    
    start = Date()
    nonAsciiDoc.insert("Hello", at: asciiDoc.startIndex)
    let nonAsciiDuration = Date().timeIntervalSince(start)

    let diff = abs(nonAsciiDuration - asciiDuration)
    XCTAssert(diff < 0.01, "Unexpected performance different in ASCII and non ASCII content.  Ascii: \(asciiDuration).  Non-Ascii: \(nonAsciiDuration).  Difference: \(asciiDuration - nonAsciiDuration)")
  }
  
  func testOffsetSpeed() {
    var start = Date()
    let doc = StringDocument(string: randomString(numberOfLines: 1000000, lineLength: 100) + "🏃🏽‍♀️£")
    print("Took \(Date().timeIntervalSince(start))s")

    start = Date()
    var idx = doc.index(doc.startIndex, offsetBy: 900000)
    print("Took \(Date().timeIntervalSince(start))s")

    start = Date()
    doc.insert("Hello\n", at: idx)
    print("Slow insertion Took \(Date().timeIntervalSince(start))s")
    
    idx = doc.index(doc.startIndex, offsetBy: 900000)

    start = Date()
    doc.insert("Hello", at: idx)
    print("Fast insertion Took \(Date().timeIntervalSince(start))s")
    
    start = Date()
    let _ = doc.calculateLineIndicesFromUTF8LineRanges(doc.lineCharacterRanges)
    print("Line Calc Took \(Date().timeIntervalSince(start))s")
  }
}

class TestMarker: DocumentMarker {
  
  var range: Range<Int>
  
  required init(range: Range<Int>) {
    self.range = range
  }
  
  func copy() -> Self {
    return type(of: self).init(range: range)
  }
}
