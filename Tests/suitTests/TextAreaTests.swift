import XCTest
import SuitTestUtils
@testable import Suit

class TextAreaTests: XCTestCase {
  
  func testTextAreaLineCount() {
    let textArea = createTextArea()
    populate(textArea: textArea, withNumberOfLines: 4, lineLength: 1000)
    textArea.resizeToFitContent()
    XCTAssertEqual(textArea.lineRectCache.count, 4)
  }
  
  func testTextAreaOffsetConversion() {
    let textArea = createTextArea()
    let numberOfLines = 100
    let lineLength = 10
    populate(textArea: textArea, withNumberOfLines: numberOfLines, lineLength: lineLength)
    
    let position = textArea.convertOffsetToLinePosition(textArea.state.text.startIndex)
    XCTAssertNotNil(position)
    XCTAssert(position!.line == 1)
    XCTAssert(position!.column == 0)
    
    let doc = textArea.state.text
    
    let line2Offset = doc.index(doc.startIndex, offsetBy: 11)
    let line2Position = textArea.convertOffsetToLinePosition(line2Offset)
    XCTAssertNotNil(line2Position)
    XCTAssert(line2Position!.line == 2)
    XCTAssert(line2Position!.column == 0)
    
    let col5Offset = doc.index(doc.startIndex, offsetBy: 49)
    let col5Position = textArea.convertOffsetToLinePosition(col5Offset)
    XCTAssertNotNil(col5Position)
    XCTAssert(col5Position!.line == 5)
    XCTAssert(col5Position!.column == 5)
    
    let end = (numberOfLines * (lineLength + 1)) - 1  // + 1 for the \n on all but the last line.
    let endOffset = doc.index(doc.startIndex, offsetBy: end)

    let endPosition = textArea.convertOffsetToLinePosition(endOffset)
    XCTAssertNotNil(endPosition)
    XCTAssert(endPosition!.column == lineLength)
    XCTAssert(endPosition!.line == numberOfLines)
  }
  
  func testCaretMovementSimple() {
    let textArea = createTextArea()
    let numberOfLines = 100
    let lineLength = 10
    populate(textArea: textArea,
             withNumberOfLines: numberOfLines,
             lineLength: lineLength)
    
    textArea.position = 0
    
    let downKey = TestKeyEvent(withCharacters: nil,
                               strokeType: .down,
                               modifiers: nil,
                               keyType: .downArrow)
    
    for i in 0..<numberOfLines - 1 {
      _ = textArea.onKeyEvent(downKey)
      let adjustment = (lineLength + 1) * (i + 1)

      XCTAssert(textArea.position == adjustment,
                "Expected positon: \(adjustment), but got: \(textArea.position!)")
    }
  }
  
  func testCaretMovement() {
    let textArea = createTextArea()

    populate(textArea: textArea, with:
    """
    Hello, this
    is
    
    a
    String...
    """)
    
    textArea.position = 0
    
    // Stays where it is when at the beginning of the document.
    textArea.onKeyEvent(leftKey)
    XCTAssert(textArea.position == 0)

    textArea.onKeyEvent(rightKey)
    XCTAssert(textArea.position == 1)
    
    textArea.onKeyEvent(rightKey)
    XCTAssert(textArea.position == 2)

    textArea.onKeyEvent(downKey)

    var linePosition = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(linePosition?.line == 2, "expected line 2, got \(linePosition!.line)")
    XCTAssert(linePosition?.column == 2, "expected column 2, got \(linePosition!.column)")
    
    textArea.onKeyEvent(downKey)
    linePosition = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(linePosition?.line == 3, "expected line 3, got \(linePosition!.line)")
    XCTAssert(linePosition?.column == 0, "expected column 0, got \(linePosition!.column)")

    textArea.onKeyEvent(downKey)
    textArea.onKeyEvent(leftKey)
    linePosition = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(linePosition?.line == 4, "expected line 4, got \(linePosition!.line)")
    XCTAssert(linePosition?.column == 0, "expected column 0, got \(linePosition!.column)")
    
    textArea.onKeyEvent(leftKey)
    textArea.onKeyEvent(leftKey)
    linePosition = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(linePosition?.line == 2, "expected line 2, got \(linePosition!.line)")
    XCTAssert(linePosition?.column == 2, "expected column 2, got \(linePosition!.column)")
    
    textArea.onKeyEvent(leftKey)
    textArea.onKeyEvent(upKey)
    linePosition = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(linePosition?.line == 1, "expected line 1, got \(linePosition!.line)")
    XCTAssert(linePosition?.column == 1, "expected column 1, got \(linePosition!.column)")
  }
  
  func testDeleteAtCaret() {
    let textArea = createTextArea()
    
    populate(textArea: textArea, with:
              """
              Hello,
               
              World!!
              
              String...
              """)
    
    textArea.position = 8
    
    var position = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssertNotNil(position)
    XCTAssert(position!.line == 2)
    XCTAssert(position!.column == 1)
    
    textArea.onKeyEvent(deleteKey)
    
    XCTAssert(textArea.position == 7)
    position = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(position?.line == 2, "expected line 2, got \(position!.line)")
    XCTAssert(position?.column == 0, "expected column 0, got \(position!.column)")
    
    textArea.onKeyEvent(deleteKey)
    XCTAssert(textArea.position == 6)
    position = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(position?.line == 1, "expected line 1, got \(position!.line)")
    XCTAssert(position?.column == 6, "expected column 6, got \(position!.column)")
  }
  
  func testMouseSelection() {
    let textArea = createTextArea()
    let numberOfLines = 100
    let lineLength = 10
    populate(textArea: textArea,
             withNumberOfLines: numberOfLines,
             lineLength: lineLength)

    // Test triple-click selects the full line.
    textArea.position = 60
    let line5Rect = textArea.lineRectCache[5]
    _ = textArea.onPointerEvent(clickEvent(line5Rect.origin, 3))
    let position66 = textArea.state.text.index(textArea.state.text.startIndex, offsetBy: 66)
    let position55 = textArea.state.text.index(textArea.state.text.startIndex, offsetBy: 55)

    XCTAssert(textArea.selectedRange == position55..<position66,
              "selected range was: \(textArea.selectedRange!), expected: 54..<65")

    // Undo selection
    _ = textArea.onPointerEvent(clickEvent(line5Rect.origin, 1))
    XCTAssert(textArea.selectedRange == nil, "Expected no selection after a single click.")

    let simpleTextArea = createTextArea()
    populate(textArea: simpleTextArea, with: "Hello, world !!")
    let position10 = textArea.state.text.index(textArea.state.text.startIndex, offsetBy: 10)
    simpleTextArea.position = 10

    // Test double-click selects the word
    _ = simpleTextArea.onPointerEvent(clickEvent(simpleTextArea.location(forIndex: position10), 2))
    XCTAssertNotNil(simpleTextArea.selectedRange)
    let position7 = textArea.state.text.index(textArea.state.text.startIndex, offsetBy: 7)
    let position12 = textArea.state.text.index(textArea.state.text.startIndex, offsetBy: 12)

    XCTAssert(simpleTextArea.selectedRange == position7..<position12,
              "Expected selection 7..12, got \(simpleTextArea.selectedRange!).")
    
    // Test double click at the end of the document.
    let endIndex = simpleTextArea.state.text.endIndex
    _ = simpleTextArea.onPointerEvent(clickEvent(simpleTextArea.location(forIndex: endIndex), 2))
    XCTAssertNil(simpleTextArea.selectedRange)
  }
  
  /// Tests that click past the end of the line brings the caret to the end of the line.
  func testMouseClickAtEnd() {
    let textArea = createTextArea()
    let numberOfLines = 100
    let lineLength = 3
    populate(textArea: textArea,
             withNumberOfLines: numberOfLines,
             lineLength: lineLength)
    
    // First check that clicking at the beginning of the line takes us to the line.
    
    let line5Rect = textArea.lineRectCache[5]
    _ = textArea.onPointerEvent(clickEvent(line5Rect.origin, 1))

    // We should now be on line 6.
    XCTAssert(textArea.position != nil, "Expected a valid position, not nil.")
    
    if let position = textArea.positionIndex {
      let lineInfo = textArea.convertOffsetToLinePosition(position)
      XCTAssert(lineInfo?.line == 6, "Expected line 6, got \(lineInfo?.line ?? -1)")
    }
    
    let endOfLine = line5Rect.offsetBy(dx: 100, dy: 0)
    _ = textArea.onPointerEvent(clickEvent(endOfLine.origin, 1))

    if let position = textArea.positionIndex {
      let lineInfo = textArea.convertOffsetToLinePosition(position)
      XCTAssert(lineInfo != nil, "Couldn't find line position")
      
      if let lineInfo = lineInfo {
        XCTAssert(lineInfo.line == 6, "Expected line 6, got \(lineInfo.line)")
        XCTAssert(lineInfo.column == 3, "Expected col 3, got \(lineInfo.column)")
      }
    }

  }
  
  func testDeleteSelection() {
    let textArea = createTextArea()
    let numberOfLines = 100
    let lineLength = 10
    populate(textArea: textArea,
             withNumberOfLines: numberOfLines,
             lineLength: lineLength)
    
    let initialCount = textArea.state.text.count
    let position60 = textArea.state.text.index(textArea.state.text.startIndex, offsetBy: 60)
    textArea.position = 60
    textArea.selectedRange = position60..<textArea.state.text.index(position60, offsetBy: 40)
    textArea.onKeyEvent(deleteKey)
    XCTAssert(textArea.state.text.count == initialCount - 40)
  }
  
  func testTriggerCharacters() {
    let textArea = createTextArea()
    let numberOfLines = 100
    let lineLength = 10
    populate(textArea: textArea,
             withNumberOfLines: numberOfLines,
             lineLength: lineLength)
    
    textArea.triggerKeyEvents = [createPlatformKeyEvent(characters: ".",
                                                        strokeType: .down,
                                                        modifiers: nil,
                                                        keyType: .other)]
    textArea.position = 0
    
    let triggerExpectation = XCTestExpectation(description: "Trigger character expectation.")
    
    textArea.onTriggerKey = { key in
      if key.characters == "." {
        triggerExpectation.fulfill()
      }
    }
    
    textArea.onKeyEvent(fullStopKey)
    wait(for: [triggerExpectation], timeout: 1)
  }
  
  func testTextInsertion() {
    let textArea = createTextArea()
    populate(textArea: textArea,
             with: "Hello ")

    textArea.position = textArea.state.text.count - 1
    XCTAssert(textArea.numberOfLines == 1)
    textArea.onKeyEvent(newLineKey)
    XCTAssert(textArea.numberOfLines == 2)
  }
  
  func testTextInsertionPerformance() {
    let textArea = createTextArea()
    let numberOfLines = 10000
    let lineLength = 100
    populate(textArea: textArea,
             withNumberOfLines: numberOfLines,
             lineLength: lineLength)

    measure {
      textArea.insert(text: "Hello",
                      at: textArea.state.text.startIndex)
    }
  }
  
  func testSymbolInsertion() {
    let textArea = createTextArea()
    let initialText = "\\ \n"
    let symbolText = "£"
    
    populate(textArea: textArea,
             with: initialText)
    
    textArea.position = 2
    
    textArea.insert(text: symbolText, at: textArea.positionIndex!)
    XCTAssert(textArea.state.text.count == initialText.count + symbolText.count)
  }
  
  func testSingleLine() {
    let textArea = createTextArea()
    populate(textArea: textArea,
             with: "12345")

    textArea.position = 0
    
    for _ in 0..<100 {
      textArea.onKeyEvent(rightKey)
    }
    
    XCTAssert(textArea.position == 5)
    XCTAssert(textArea.position == textArea.state.text.count,
              "Expected to be at the end of the document")
    
    textArea.onKeyEvent(downKey)
    XCTAssert(textArea.position == textArea.state.text.count,
              "Expected to be at the end of the document")
    
    textArea.onKeyEvent(newLineKey)
    let positionInfo = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    
    if let positionInfo = positionInfo {
      XCTAssert(positionInfo.line == 2,
                "Expected to be on line 2, but was on: \(positionInfo.line)")
      XCTAssert(positionInfo.column == 0,
                "Expected to be on column , but was on: \(positionInfo.column)")
    } else {
      XCTFail("Expected valid position info, got nil.")
    }
  }
  
  func testEditEmptyTextArea() {
    let textArea = createTextArea()
    textArea.insert(text: "l", at: textArea.state.text.startIndex)
    textArea.insert(text: "e", at: textArea.positionIndex!)
    textArea.insert(text: "t", at: textArea.positionIndex!)
    
    XCTAssert(textArea.state.text.numberOfLines == 1)

    var lineInfo = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(lineInfo?.line == 1)
    XCTAssert(lineInfo?.column == 3)
    
    var lineRange = textArea.state.text.rangeOfLine(1)!
    var lineLength = textArea.state.text.distance(from: lineRange.lowerBound,
                                                  to: lineRange.upperBound)
    XCTAssert(lineLength == 3)
    
    textArea.insert(text: "\n", at: textArea.positionIndex!)
    textArea.insert(text: "a", at: textArea.positionIndex!)

    XCTAssert(textArea.state.text.numberOfLines == 2)
    lineInfo = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(lineInfo?.line == 2)
    XCTAssert(lineInfo?.column == 1)
    
    lineRange = textArea.state.text.rangeOfLine(2)!
    lineLength = textArea.state.text.distance(from: lineRange.lowerBound,
                                                to: lineRange.upperBound)
    XCTAssert(lineLength == 1)
    
    textArea.insert(text: "\n", at: textArea.positionIndex!)
    textArea.insert(text: "ab", at: textArea.positionIndex!)

    XCTAssert(textArea.state.text.numberOfLines == 3)
    lineInfo = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    XCTAssert(lineInfo?.line == 3)
    XCTAssert(lineInfo?.column == 2)
    
    lineRange = textArea.state.text.rangeOfLine(3)!
    lineLength = textArea.state.text.distance(from: lineRange.lowerBound,
                                              to: lineRange.upperBound)
    XCTAssert(lineLength == 2)
  }

  func testEditPopulatedTextArea() {
    let textArea = createTextArea()
    populate(textArea: textArea,
             with: "12345\nabcdef\n0000\n======")
    
    XCTAssert(textArea.state.text.numberOfLines == 4)

    var secondLine = textArea.state.text.rangeOfLine(2)!
    var secondLineLength = textArea.state.text.distance(from: secondLine.lowerBound,
                                                        to: secondLine.upperBound)
    XCTAssert(secondLineLength == 7)

    
    let endOfSecondLine = textArea.state.text.index(before:
                                          secondLine.upperBound)
    textArea.position = textArea.state.text.distance(from: textArea.state.text.startIndex,
                                                     to: endOfSecondLine)
    textArea.insert(text: "g", at: endOfSecondLine)
    
    XCTAssert(textArea.state.text.numberOfLines == 4)
    
    secondLine = textArea.state.text.rangeOfLine(2)!
    secondLineLength = textArea.state.text.distance(from: secondLine.lowerBound,
                                                    to: secondLine.upperBound)
    XCTAssert(secondLineLength == 8)
  }
  
  func testEmptyLastLine() {
    let textArea = createTextArea()
    populate(textArea: textArea,
             with: "12345\n\n")
    
    textArea.position = 0
    
    textArea.onKeyEvent(downKey)
    textArea.onKeyEvent(downKey)

    let positionInfo = textArea.convertOffsetToLinePosition(textArea.positionIndex!)
    
    if let positionInfo = positionInfo {
      XCTAssert(positionInfo.line == 3,
                "Expected to be on line 3, but was on: \(positionInfo.line)")
      XCTAssert(positionInfo.column == 0,
                "Expected to be on column , but was on: \(positionInfo.column)")
    } else {
      XCTFail("Expected valid position info, got nil.")
    }
  }
  
  ///
  /// Test that the reported visible columns are correct when the text area is scrolled.
  ///
  func testVisibleColumnsCalculation() {
    let textArea = createTextArea()
    let numberOfColumns = 20
    let content = String(repeating: "_", count: numberOfColumns)
    populate(textArea: textArea,
             with: content)
    
    let charSize = textArea.graphics.size(of: "_",
                                          wrapping: .none)
    
    textArea.height = 100%
    textArea.width = 100~

    let scrollView = ScrollView()
    scrollView.add(subview: textArea)
    scrollView.height = 100~
    scrollView.width = 10~
    
    window.rootView = scrollView
    scrollView.invalidateLayout()
    
    var horizontalScrollAmount: CGFloat = 0
    
    // Scroll across the text view and ensure that the visibleColumns are as expected.
    //
    while horizontalScrollAmount > -(textArea.frame.width + 10) {
      scrollView.scroll(to: CGPoint(x: horizontalScrollAmount, y: 0))
      let visibleColumns = textArea.visibleColumns(onLine: 1)
      
      let expectedColumnsStart = Int(abs(scrollView.xOffsetTotal / charSize.width))
      var expectedColumnsEnd = Int((scrollView.frame.width + -scrollView.xOffsetTotal) / charSize.width)
      expectedColumnsEnd = Int(min(expectedColumnsEnd, numberOfColumns))
      
      XCTAssert(visibleColumns.lowerBound == expectedColumnsStart,
                "Scrolled text area's visible columns should start at 1.")
      XCTAssert(Int(expectedColumnsEnd) == visibleColumns.upperBound - 1,
                "End visible column is not as expected.")
      
      horizontalScrollAmount -= 5
    }
  }
}
