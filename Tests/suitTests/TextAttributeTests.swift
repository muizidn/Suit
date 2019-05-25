//
//  TextAttributeTests.swift
//  SuitTests
//
//  Created by pmacro on 09/02/2019.
//

import XCTest
import SuitTestUtils
@testable import Suit

class TextAttributeTests: XCTestCase {
 
  func testSimpleTextAttributes() {
    var textAttributes = [TextAttribute]()
    var current = 0
    
    for _ in 1..<1000 {
      let next = current + 9
      textAttributes.append(TextAttribute(color: .blue, range: current..<next))
      current = next + 1
    }

    let start = Date()
    let firstTwoLines = textAttributes.in(range: 5..<20)
    print("Time: \(Date().timeIntervalSince(start))s")
    XCTAssert(firstTwoLines?.count == 2)
    
    let singleLineInMiddle = textAttributes.in(range: 5000..<5001)
    XCTAssert(singleLineInMiddle?.count == 1)

    let tenLines = textAttributes.in(range: 1000..<1100)
    XCTAssert(tenLines?.count == 10)
  }
  
  func testTextAreaAttributes() {
    let textArea = createTextArea()
    populate(textArea: textArea, withNumberOfLines: 100, lineLength: 10)

    var textAttributes = [TextAttribute]()
    
    for i in 1..<100 {
      let start = i * 10
      textAttributes.append(TextAttribute(color: .blue,
                                          range: start..<start + 10))
    }
    

    textArea.state.text.textAttributes = textAttributes

    let attributes = textAttributes.in(range: 15..<25)
    XCTAssert(attributes?.count == 2)
  }
  
  ///
  /// Attempts to test a realistic large document.
  ///
  func testTextAreaAttributesPerformance() {
    var textAttributes = [TextAttribute]()
    var current = 0
    let numberOfLines = 30000
    let lineLength = 120
    
    var content = ""

    for _ in 1..<numberOfLines {
      var i = 0

      // Add an attribute every 10 characters.  Seems fairly realistic over a document.
      while i < lineLength {
        textAttributes.append(TextAttribute(color: .blue, range: current..<current + i))
        current += 11
        i += 10
      }
      content += randomString(length: lineLength - 1) + "\n"
    }
    
    XCTAssert(textAttributes.count > 200000,
              "Bad test code.  Generated textAttributes aren't as expected meaning this test is invalid.  Number found: \(textAttributes.count)")

    let document = StringDocument(stringLiteral: content)

    // Ensure things are setup as expected and that this is therefore a valid test.
    XCTAssert(document.numberOfLines == numberOfLines)
    
    document.textAttributes = textAttributes
    
    measure {
      document.insert("a", at: document.startIndex)
    }
  }
}
