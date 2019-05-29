//
//  TextAreaView.swift
//  Suit
//
//  Created by pmacro on 13/06/2018.
// 

import Foundation

// The direction to go when navigating through the next.
public enum SearchDirection { 
  case left
  case right
  case both
}

///
/// A text area's document state.
///
open class TextAreaState {
  public var text: StringDocument = ""
}

///
/// A text area renderer.
///
open class TextAreaRenderer {
  public typealias TextAreaDecorator = (_ lineNumber: Int, _ rect: CGRect, _ graphics: Graphics) -> Void

  /// The width of the gutter.
  public var gutterWidth: CGFloat = 50
  
  /// The width of the gutter's vertical divider line.
  public var gutterDividerWidth: CGFloat = 0.2
  
  /// Should the current line be rendered a different colour from other lines?
  /// False by default.
  public var indicatesCurrentLine = false
  
  /// Should line numbers she rendered as part of the gutter?  Defaults to true.
  public var showLineNumbersInGutter = true

  // The actual gutter width, returning 0 is showGutter is false.
  var activeGutterWidth: CGFloat {
    return showGutter ? gutterWidth : 0
  }

  /// Should the gutter area be rendered?
  public var showGutter: Bool = false

  var decorators: [TextAreaDecorator]?
  var gutterDecorators: [TextAreaDecorator]?

  public func add(decorator: @escaping TextAreaDecorator) {
    decorators = decorators ?? []
    decorators?.append(decorator)  
  }

  public func add(gutterDecorator: @escaping TextAreaDecorator) {
    gutterDecorators = gutterDecorators ?? []
    gutterDecorators?.append(gutterDecorator)
  }

  ///
  /// Renders the dirty, visible portion of the text area.
  ///
  public func render(state: TextAreaState,
                     using graphics: Graphics,
                     in rect: CGRect,
                     from textAreaView: TextAreaView) {

    let text = textAreaView.state.text

    graphics.set(color: textAreaView.textColor)
    graphics.set(font: textAreaView.font)
    let currentLine = textAreaView.currentLine

    let visibleLines = textAreaView.visibleLines.clamped(to: 0..<text.numberOfLines)

    let scrollOffsets = textAreaView.embeddingScrollView?.contentWrapper.bounds.origin
      ?? .zero

    var startPoint = rect.origin
    startPoint.x -= scrollOffsets.x
    startPoint.y -= scrollOffsets.y

    let endPoint = CGPoint(x: (rect.origin.x + rect.width) - scrollOffsets.x,
                           y: (rect.origin.y + rect.height) - scrollOffsets.y)

    let dirtyLineRects = textAreaView.lineRectsBetween(startPoint: startPoint,
                                                       endPoint: endPoint)

    // Render each line.
    for dirtyLine in dirtyLineRects {
      let lineNumber = dirtyLine.key
      let lineBox = dirtyLine.value

      if !visibleLines.contains(lineNumber - 1 ) {
        continue
      }

      guard let lineRange = text.rangeOfLine(lineNumber) else {
        break
      }

      let line = text[lineRange]

      // Paint text selection.
      if let rect = textAreaView.selectedLineRects[lineNumber] {
        self.renderLineBackground(using: graphics,
                                  in: rect,
                                  from: textAreaView,
                                  color: .textSelectionColor)
      }
        // Indicate the current line.
      else if indicatesCurrentLine, lineNumber == currentLine {
        var rect = lineBox
        rect.origin.x = 0
        let colour: Colour = Appearance.current == .light ? .lighterBlue : .darkerGray
        self.renderLineBackground(using: graphics,
                                  in: rect,
                                  from: textAreaView,
                                  fullWidth: true,
                                  color: colour)
      }

      graphics.set(color: textAreaView.textColor)

      let lineAttributes = text.textAttributesByLine[safe: lineNumber - 1] ?? []

      self.render(line: String(line),
                  using: graphics,
                  in: lineBox,
                  with: lineAttributes)

      // Render the caret.
      if currentLine == lineNumber,
        textAreaView.caretOn, textAreaView.selectedLineRects.isEmpty {
        renderCaret(using: graphics,
                    on: lineBox,
                    from: textAreaView)
      }


      decorators?.forEach { $0(lineNumber, lineBox, graphics) }
    }

    if showGutter {
      renderGutter(using: graphics,
                   in: rect,
                   lines: visibleLines,
                   lineRects: textAreaView.lineRectCache,
                   currentLine: currentLine)
    }
  }

  ///
  /// Render a line.
  ///
  func render(line: String,
              using graphics: Graphics,
              in rect: CGRect,
              with lineAttributes: [TextAttribute]?) {
    graphics.draw(text: line,
                  inRect: rect,
                  horizontalArrangement: .left,
                  verticalArrangement: .top,
                  with: lineAttributes,
                  wrapping: .none)
  }

  ///
  /// Render a line's background.
  ///
  func renderLineBackground(using graphics: Graphics,
                            in rect: CGRect,
                            from textAreaView: TextAreaView,
                            fullWidth: Bool = false,
                            color: Color) {
    var lineRect = rect
    // ensure the rect is vertically centerd.
    let spacing = textAreaView.interlineSpacing + 1
    lineRect.size.height += spacing
    lineRect.origin.y -= spacing / 2

    if fullWidth {
      lineRect.size.width = max(textAreaView.frame.width,
                                textAreaView.superview?.frame.width ?? 0)
    }

    graphics.set(color: color)
    graphics.draw(rectangle: lineRect)
    graphics.fill()
  }

  ///
  /// Render the caret.
  ///
  func renderCaret(using graphics: Graphics,
                   on lineRect: CGRect,
                   from textAreaView: TextAreaView) {

    let location = textAreaView.location(forIndex: textAreaView.positionIndex
      ?? textAreaView.state.text.startIndex)

    let rect = CGRect(x: location.x,
                      y: location.y,
                      width: textAreaView.caretWidth,
                      height: lineRect.height)

    graphics.set(color: .textColor)
    graphics.draw(rectangle: rect)
    graphics.fill()
  }

  ///
  /// Render the gutter area.
  ///
  func renderGutter(using graphics: Graphics,
                    in rect: CGRect,
                    lines: Range<Int>,
                    lineRects: [CGRect],
                    currentLine: Int?) {

    // The space between the gutter line and the text.
    let spaceToText: CGFloat = 10

    // The space between the line number and the gutter line.
    let spaceToGutterLine: CGFloat = 5

    var gutterRect = rect
    gutterRect.size.width = gutterDividerWidth
    gutterRect.origin.x = gutterWidth - gutterDividerWidth - spaceToText

    graphics.set(color: .darkerGray)
    graphics.draw(rectangle: gutterRect)
    graphics.fill()

    let gutterLineNumberWidth = gutterWidth - spaceToText - spaceToGutterLine

    for line in lines {
      guard let lineRect = lineRects[safe: line] else { break }

      var lineNumberRect = lineRect
      lineNumberRect.size.width = gutterLineNumberWidth
      lineNumberRect.origin.x = 0

      if showLineNumbersInGutter {
        let style = Appearance.current

        if line + 1 == currentLine {
          graphics.set(color: style == .light ? .darkerGray : .white)
        } else {
          graphics.set(color: .lightGray)
        }

        graphics.draw(text: "\(line + 1)",
          inRect: lineNumberRect,
          horizontalArrangement: .right,
          verticalArrangement: .top,
          with: nil,
          wrapping: .word)
      }
      gutterDecorators?.forEach { $0(line + 1, lineNumberRect, graphics) }
    }
  }
}

///
/// A text area view displays text, and supports editing, selection, styling and other
/// advanced operations.
///
open class TextAreaView: View {
  
  /// The text area's font.
  public var font: Font = .ofType(.system, category: .medium) {
    didSet {
      resizeToFitContent()
    }
  }

  /// The renderer for the text area.
  lazy open var renderer: TextAreaRenderer = TextAreaRenderer()
  
  /// The text area's state.
  lazy open var state: TextAreaState = TextAreaState()
  
  /// The range of selected text, if any.
  var selectedRange: Range<String.Index>?

  /// The speed at which the caret should switch from visible to invisible.
  var caretBlinkSpeed = 0.7
  
  /// The timer that manages caret "blinking".
  let caretTimer: RepeatingTimer
  
  // Tracks the current blinking state of the caret.
  fileprivate var caretOn = true

  /// The width of the caret.
  var caretWidth: CGFloat = 1

  /// Key events that should result in the trigger methods being invoked.
  public var triggerKeyEvents = [KeyEvent]()

  /// Configures the `showGutter` property on the renderer.
  public var showGutter = false {
    didSet {
      renderer.showGutter = showGutter
    }
  }

  /// The number of lines in the text area.
  var numberOfLines: Int {
    return state.text.numberOfLines
  }

  /// The line of the current insertion point.
  public private(set) var currentLine: Int?
  
  /// The column of the current insertion point.
  public private(set) var currentColumn: Int?

  /// If read only, the text area cannot be edited in any way.  This is true by default.
  public var readOnly: Bool = true

  /// When the user uses the up/down arrow keys they expect the column
  /// to stay the same until they manually change it.  This tracks the expected column.
  private var expectedColumn: Int?

  /// The insertion point, in String index terms.
  public var positionIndex: String.Index?

  /// The insertion point in terms of character count.
  public var position: Int? {
    didSet {
      if let position = position {
        if position != oldValue {
          didChangePosition()
        }
      }
      else {
        positionIndex = nil
      }
    }
  }

  /// The spacing between rendered lines.
  var interlineSpacing: CGFloat = 1

  /// A cache of the geometry of each line of text.
  var lineRectCache = [CGRect]()
  
  /// The geometry of each selected line.
  var selectedLineRects = [Int : CGRect]()
  
  /// When selecting text via a pointer device, this tracks the point where the selection began.
  var currentSelectionStartPoint: CGPoint?

  public typealias OnTriggerKey = (KeyEvent) -> Void
  public var onTriggerKey: OnTriggerKey?

  /// The default text color for the text area.
  public var textColor: Color = .darkTextColor {
    didSet {
      userChangedDefaultTextColor = true
    }
  }

  /// The range of line numbers currently visible in the text area.  This accounts for
  /// this text area being embedded inside a scroll view, and will return the visible lines
  /// within the scroll view.
  public var visibleLines: Range<Int> {
    if let scrollView = embeddingScrollView {
      let scrollOffsets = scrollView.contentWrapper.bounds.origin

      var visibleArea = visibleRect.offsetBy(dx: -scrollOffsets.x, dy: -scrollOffsets.y)
      visibleArea.size.height = scrollView.frame.height

      let firstLine = lineRectNearest(point: visibleArea.origin)

      let endPoint = CGPoint(x: visibleArea.origin.x + visibleArea.width,
                             y: visibleArea.origin.y + visibleArea.height)

      let lastLine = lineRectNearest(point: endPoint)

      if let start = firstLine?.0, let end = lastLine?.0 {
        if start < end {
          return start..<end
        }
        return end..<start
      }
    }

    return 0..<numberOfLines
  }
  
  public func visibleColumns(onLine line: Int) -> Range<Int> {
    if let scrollView = embeddingScrollView {
      let scrollOffsets = scrollView.contentWrapper.bounds.origin
      
      let lineRect = lineRectCache[line - 1]
      
      let visibleArea = CGRect(x: lineRect.origin.x - scrollOffsets.x,
                               y: lineRect.origin.y,
                               width: scrollView.frame.width,
                               height: lineRect.height)
      
      guard let lineRange = state.text.rangeOfLine(line) else {
        return 0..<0
      }
      
      let start = indexNearest(point: visibleArea.origin) ?? lineRange.lowerBound
      let end = indexNearest(point: CGPoint(x: visibleArea.origin.x + visibleArea.width,
                                            y: visibleArea.origin.y)) ?? lineRange.upperBound

      let finalStart = lineRange.contains(start) ? start : lineRange.lowerBound
      let finalEnd = lineRange.contains(end) ? end : lineRange.upperBound
      
      let startCol = state.text.distance(from: lineRange.lowerBound, to: finalStart)
      let endCol = state.text.distance(from: lineRange.lowerBound, to: finalEnd)
      
      return startCol..<endCol
    }
    
    return 0..<(state.text.lineCharacterRanges.last?.upperBound ?? 0)
  }

  /// This is used to track whether or not it's safe for us to automatically
  /// change the text color for the user whenever the Appearance changes.
  /// We'll only do it if the user has not updated the text color.
  private var userChangedDefaultTextColor = false 

  required public init() {
    caretTimer = RepeatingTimer(timeInterval: caretBlinkSpeed)
    super.init()
    insets = EdgeInsets(left: 0, right: 0, top: 2, bottom: 5)
    position = nil

    caretTimer.callback = { [weak self] in
      DispatchQueue.main.async {
        guard let `self` = self else { return }
        self.caretOn = self.hasKeyFocus ? !self.caretOn : false

        let lineRect = self.lineRect(forIndex: self.positionIndex ?? self.state.text.startIndex)
        var origin = self.location(forIndex:
          self.positionIndex ?? self.state.text.startIndex)
        origin.x += self.frame.origin.x
        origin.y += self.frame.origin.y
        let rect = CGRect(origin: origin,
                          size: CGSize(width: self.caretWidth,
                                       height: lineRect?.height ?? 10))

        self.window?.redrawManager.redraw(view: self,
                                          dirtyRect: rect)

        if !self.hasKeyFocus { self.caretTimer.stop() }
      }
    }
    caretTimer.resume()
  }

  ///
  /// Draw the text area.
  ///
  public override func draw(rect: CGRect) {
    super.draw(rect: rect)
    renderer.render(state: state, using: graphics, in: rect, from: self)
  }

  ///
  /// Invalidates the appropriate parts of the text area whenever the insertion point
  /// changes.
  ///
  private func didChangePosition() {
    guard let position = position else { return }

    let oldLine = currentLine
    let index = state.text.index(state.text.startIndex, offsetBy: position)
    positionIndex = index

    let positionInfo = convertOffsetToLinePosition(index)
    currentLine = positionInfo?.line
    currentColumn = positionInfo?.column
    
    guard let oldLineNumber = oldLine,
      let currentLineNumber = currentLine,
      selectedLineRects.isEmpty else
    {
      window.redrawManager.redraw(view: self)
      return
    }
    
    // If the new position is offscreen, we need to scroll to it.  And since the scrolling code
    // will take care of the redraw, we can exit this function.
    if scrollToLineIfOffscreen(currentLineNumber) || scrollToColumnIfOffscreen(currentColumn ?? 0,
                                                                               onLine: currentLineNumber) {
      return
    }

    // Try to be as efficient as possible in calculating dirty areas as this will have a
    // very large impact on editor performance.

    // If we haven't changed lines just redraw the current line.
    // TODO: we could further optimize this by only drawing what's changed.
    if oldLineNumber == currentLineNumber {
      if let dirtyRect = lineRectCache[safe: currentLineNumber - 1] {

        window.redrawManager.redraw(view: self,
                                    dirtyRect: dirtyRect.offsetBy(dx: frame.origin.x,
                                                                  dy: frame.origin.y))
      }
    }
    else {
      let lineRange: ClosedRange<Int>

      if oldLineNumber > currentLineNumber {
        lineRange = currentLineNumber...oldLineNumber
      } else {
        lineRange = oldLineNumber...currentLineNumber
      }

      var rects = [CGRect]()
      for line in lineRange {
        if let rect = lineRectCache[safe: line - 1] {
          // We adjust the rect here because we need to account for interline spacing,
          // and because we want to dirty the whole line (including the gutter),
          // not just the text.
          var dirtyRect = rect
          dirtyRect.origin.x = 0
          dirtyRect.origin.y -= interlineSpacing / 2
          dirtyRect.size.height += interlineSpacing
          rects.append(dirtyRect)
        }
      }

      if let dirtyRect = rects.union() {
        window.rootView.invalidateLayout()
        window.redrawManager.redraw(view: self, dirtyRect: dirtyRect)
      }
    }
  }

  ///
  /// Handles pointer events for selection etc.
  ///
  override open func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    if super.onPointerEvent(pointerEvent) {
      return true
    }

    if pointerEvent.type == .click {
      window.lockFocus(on: self)
      caretTimer.resume()
      makeKeyView()
      return handleMouseClick(pointerEvent)
    }
    else if pointerEvent.type == .drag {
      return handleDrag(pointerEvent)
    }
    else if pointerEvent.type == .enter {
      Cursor.shared.push(type: .iBeam)
    }
    else if pointerEvent.type == .exit {
      Cursor.shared.pop()
    }
    else if pointerEvent.type == .release {
      currentSelectionStartPoint = nil
    }

    return false
  }

  private func handleMouseClick(_ event: PointerEvent) -> Bool {
    guard let index = indexNearest(point: windowCoordinatesInViewSpace(from: event.location)) else {
      return false
    }

    position = state.text.distance(from: state.text.startIndex, to: index)

    if event.eventCount == 2 {
      if let positionIndex = positionIndex, let line = lineNumber(containing: positionIndex) {
        let selectionIndices = wordIndicesNearest(index: positionIndex)
        let rect = rectOfIndicesWithinSingleLine(selectionIndices)
        selectedRange = selectionIndices
        selectedLineRects = [line: rect]
        currentSelectionStartPoint = rect.origin
        self.position = state.text.distance(from: state.text.startIndex,
                                            to: selectionIndices.lowerBound)
      }
    }

    else if event.eventCount == 3 {
      if let positionIndex = positionIndex, let line = lineNumber(containing: positionIndex) {
        select(line: line)
        currentSelectionStartPoint = selectedLineRects[line - 1]?.origin
      }
    }

    else if event.type == .click, !selectedLineRects.isEmpty {
      selectedLineRects.removeAll()
      selectedRange = nil
      window.redrawManager.redraw(view: self)
    }

    return true
  }

  ///
  /// Selects the text on `line`.
  ///
  public func select(line: Int) {
    guard let rect = lineRectCache[safe: line - 1],
      let selectionRange = state.text.rangeOfLine(line) else { return }

    selectedLineRects = [line: rect]
    self.selectedRange = selectionRange

    if line < state.text.numberOfLines {
      let offset = state.text.index(before: selectionRange.upperBound)
      self.position = state.text.distance(from: state.text.startIndex, to: offset)
    }
  }

  ///
  /// Selects the text within the specified range.
  ///
  public func select(range: Range<String.Index>) {    
    self.selectedRange = range
    guard let line = convertOffsetToLinePosition(range.lowerBound)?.line else {
      return
    }

    let startPoint = location(forIndex: range.lowerBound)
    let endPoint = location(forIndex: range.upperBound)

    selectedLineRects = lineRectsBetween(startPoint: startPoint, endPoint: endPoint)

    if line < state.text.numberOfLines {
      let offset = state.text.index(before: range.upperBound)
      self.position = state.text.distance(from: state.text.startIndex, to: offset)
    }
  }
  
  ///
  /// Handle dragging, in particular the dragged selection of text.
  ///
  func handleDrag(_ pointerEvent: PointerEvent) -> Bool {
    let pointerPoint = windowCoordinatesInViewSpace(from: pointerEvent.location)
    let isStartingSelection = currentSelectionStartPoint == nil
    
    if isStartingSelection {
      currentSelectionStartPoint = pointerPoint
      
      // If there's an existing selection (from a triple/double click for instance), start from its start point.
      if !selectedLineRects.isEmpty {
        currentSelectionStartPoint = selectedLineRects.first?.value.origin
      }
    }
    
    guard let selectionStartPoint = currentSelectionStartPoint,
          let currentLine = currentLine,
          let offset = indexNearest(point: pointerPoint) else { return true }
    
    // If the drag is outside the visible lines, scroll to the line nearest the pointer.
    if let lineNearestPointer = lineRectNearest(point: pointerPoint)?.0 {
      if lineNearestPointer > currentLine {
        scrollToLineIfOffscreen(currentLine + 1)
      }
      else if lineNearestPointer < currentLine {
        scrollToLineIfOffscreen(currentLine - 1)
      }
    }
    
    // Scroll to the column we're dragging at.
    if let scrollColumn = self.convertOffsetToLinePosition(offset)?.column {
      scroll(toColumn: scrollColumn, onLine: currentLine)
    }
    
    let selectionEndPoint = pointerPoint
    let shouldFlipPoints = selectionEndPoint.y < selectionStartPoint.y
    
    let start = shouldFlipPoints ? selectionEndPoint : selectionStartPoint
    let end = shouldFlipPoints ? selectionStartPoint : selectionEndPoint
    
    selectedLineRects = lineRectsBetween(startPoint: start,
                                         endPoint: end)

    position = state.text.distance(from: state.text.startIndex, to: offset)

    if let positionIndex = positionIndex,
      let selectionStartIdx = indexNearest(point: start) {
      if positionIndex < selectionStartIdx {
        selectedRange = positionIndex..<selectionStartIdx
      } else {
        selectedRange = selectionStartIdx..<positionIndex
      }
    }

    return true
  }

  open override func didAttachToWindow() {
    super.didAttachToWindow()
    resizeToFitContent()
  }

  open override func didResignAsKeyView() {
    super.didResignAsKeyView()
    caretTimer.stop()
    currentSelectionStartPoint = nil
  }

  func resizeToFitContent(onLine lineNumber: Int) {
    if state.text.numberOfLines == 1 {
      resizeToFitContent()
      return
    }

    guard let range = state.text.rangeOfLine(lineNumber) else { return }
    let line = state.text[range]
    let lineToMeasure = line.trimmingCharacters(in: .whitespacesAndNewlines)

    let minWidth = max(bounds.width, embeddingScrollView?.frame.width ?? 0)
    var lineBox = graphics.size(of: lineToMeasure.isEmpty ? "||" : String(line).trimmingCharacters(in: .newlines), wrapping: .none)
    lineBox.size.width = max(minWidth, lineBox.size.width)

    var existingLineBox = lineRectCache[lineNumber - 1]
    existingLineBox.size.width = frame.width

    let minAreaHeight = max(lineBox.size.height, existingLineBox.size.height)
    existingLineBox.size.height = minAreaHeight

    self.lineRectCache[lineNumber - 1] = existingLineBox

    let newWidth = max(self.frame.width,
                       lineBox.size.width + renderer.activeGutterWidth + insets.left + insets.right)

    if self.width.unit == .point || self.width.unit == .auto, newWidth > self.frame.width {
      self.width = max(newWidth, CGFloat(self.width.value))~
    }
  }

  func resizeToFitContent() {
    guard ensureGraphics(), let graphics = graphics else {
      frame = superview?.bounds ?? frame
      return
    }

    let textAreaInsets = insets
    let lineSpacing = interlineSpacing

    var width: CGFloat = 0
    var height: CGFloat = textAreaInsets.top

    lineRectCache.removeAll()

    var y: CGFloat = insets.top
    var characterCount = 0
    graphics.set(font: font)

    let minWidth = max(bounds.width, embeddingScrollView?.frame.width ?? 0)

    for i in 0..<state.text.numberOfLines {
      guard let range = state.text.rangeOfLine(i + 1) else {
        print("Expected cached line range, but couldn't find it.  This is a bug.")
        return
      }

      let line = state.text[range]
      let lineToMeasure = line.trimmingCharacters(in: .whitespacesAndNewlines)

      var lineBox = graphics.size(of: lineToMeasure.isEmpty ? "||" : String(line).trimmingCharacters(in: .newlines), wrapping: .none)
      lineBox.size.width = max(minWidth, lineBox.size.width)
      width = max(width, lineBox.size.width)
      height += lineBox.height + lineSpacing

      characterCount += line.distance(from: line.startIndex, to: line.endIndex)
      lineBox.origin.y = y
      lineBox.origin.x = insets.left + renderer.activeGutterWidth

      self.lineRectCache.append(lineBox)

      y = height
    }

    height += textAreaInsets.bottom

    self.height = height~

    if self.width.unit == .point || self.width.unit == .auto, width > self.frame.width {
      self.width = max(width, CGFloat(self.width.value))~
    }
  }

  public func dimensionsOfLine(nearest point: CGPoint) -> CGRect? {
    return lineRectNearest(point: point)?.1
  }

  func lineRects(forRange range: Range<String.Index>) -> [Int : CGRect]? {
    let startLine = lineNumber(containing: range.lowerBound)
    let endLine = lineNumber(containing: range.upperBound)

    guard let start = startLine, let end = endLine else { return nil }

    if start == end {
      return [start: lineRectCache[start - 1]]
    }

    var lineRects = [Int : CGRect]()

    for i in start...end {
      lineRects[i] = lineRectCache[i - 1]
    }

    return lineRects.isEmpty ? nil : lineRects
  }

  func lineNumber(containing index: String.Index) -> Int? {
    return convertOffsetToLinePosition(index)?.line
  }

  func lineRect(forIndex index: String.Index) -> CGRect? {
    if let line = lineNumber(containing: index) {
      return lineRectCache[safe: line - 1]
    }
    return nil
  }

  func lineRectsBetween(startPoint: CGPoint, endPoint: CGPoint) -> [Int : CGRect] {
    let startPoint = CGPoint(x: startPoint.x - frame.origin.x,
                             y: startPoint.y + frame.origin.y)
    let endPoint = CGPoint(x: endPoint.x - frame.origin.x,
                           y: endPoint.y + frame.origin.y)

    guard let startInfo: (idx: Int, rect: CGRect) = lineRectNearest(point: startPoint),
      let endInfo: (idx: Int, rect: CGRect) = lineRectNearest(point: endPoint) else {
        return [:]
    }

    let firstLine = startInfo.idx + 1
    let lastLine = endInfo.idx + 1

    let rects: ArraySlice<CGRect>

    if startInfo.idx < endInfo.idx {
      rects = lineRectCache[startInfo.idx...endInfo.idx]
    } else {
      rects = lineRectCache[endInfo.idx...startInfo.idx]
    }

    let onSameLine = firstLine == lastLine

    // Ensure the start and end points in order.
    let shouldFlipPoints = onSameLine ? startPoint.x > endPoint.x : startPoint.y > endPoint.y
    let start =  shouldFlipPoints ? endPoint : startPoint
    let end =  shouldFlipPoints ? startPoint : endPoint

    var preliminaryLineRects = Array(rects)

    if let firstLineRect = preliminaryLineRects.first {
      var rect = firstLineRect
      rect.origin.x = horizontalPositionOfCharacterNearest(x: start.x, onLine: firstLine)
      rect.size.width -= start.x - rect.origin.x
      preliminaryLineRects[0] = rect
    }

    if let lastLineRect = preliminaryLineRects.last {
      var rect = lastLineRect
      let x = end.x - rect.origin.x
      rect.size.width = horizontalPositionOfCharacterNearest(x: x,
                                                             onLine: lastLine,
                                                             adjustForInsets: false)
      preliminaryLineRects[preliminaryLineRects.count - 1] = rect
    }

    var result = [Int: CGRect]()
    let offset = shouldFlipPoints ? endInfo.idx : startInfo.idx

    for (index, rect) in preliminaryLineRects.enumerated() {
      result[offset + index + 1] = rect
    }

    return result
  }

  func rangeOfTextBetween(startPoint: CGPoint, endPoint: CGPoint) -> Range<String.Index>? {
    let start = indexNearest(point: startPoint) ?? state.text.startIndex
    let end = indexNearest(point: endPoint) ?? state.text.endIndex

    if start < end {
      return start..<end
    } else if end < start {
      return end..<start
    }

    return nil
  }

  open func location(forIndex index: String.Index) -> CGPoint {
    guard let line = lineNumber(containing: index),
      let rect = lineRectCache[safe: line - 1],
      let lineIndices = state.text.rangeOfLine(line) else { return .zero }

    var currentX = rect.origin.x
    let stateString = state.text

    if index == lineIndices.lowerBound {
      return CGPoint(x: currentX, y: rect.origin.y)
    }

    var currentIndex: String.Index? = lineIndices.lowerBound

    while let current = currentIndex, current < index {
      let characterWidth = graphics.size(of: String(stateString[current]), wrapping: .none).width
      currentX += characterWidth
      currentIndex = state.text.index(after: current)
    }

    return CGPoint(x: currentX, y: rect.origin.y)
  }

  ///
  /// For a given position on a line, returns the position nearest a character boundary.
  ///
  func horizontalPositionOfCharacterNearest(x: CGFloat,
                                            onLine line: Int,
                                            adjustForInsets: Bool = true) -> CGFloat {
    guard let lineIndices = state.text.rangeOfLine(line) else {
      return lineRectCache.last?.origin.x ?? insets.left + renderer.activeGutterWidth
    }
    var currentIndex: String.Index? = lineIndices.lowerBound
    var currentX = adjustForInsets ? insets.left + renderer.activeGutterWidth : 0

    while let current = currentIndex, current < lineIndices.upperBound {
      let characterWidth = graphics.size(of: String(state.text[current]), wrapping: .none).width
      if x > currentX + (characterWidth / 2) {
        currentX += characterWidth
      } else {
        break
      } 

      currentIndex = self.state.text.index(after: current)
    }

    return currentX
  }

  func indexNearest(point: CGPoint) -> String.Index? {
    // Normalize for this view's space.
    let point = CGPoint(x: point.x - frame.origin.x,
                        y: point.y + frame.origin.y)

    guard let index = lineRectNearest(point: point)?.0,
      let lineIndices = state.text.rangeOfLine(index + 1) else { return nil }

    // Convert from UTF8.
    guard let lineStart = lineIndices.lowerBound.samePosition(in: state.text.buffer),
      let lineEnd = lineIndices.upperBound.samePosition(in: state.text.buffer) else {
        return nil
    }

    let isLastLine = index + 1 == numberOfLines
    var currentIndex: String.Index? = lineStart
    var currentX: CGFloat = insets.left + renderer.activeGutterWidth
    let stateString = state.text
    var characterWidth: CGFloat = -1

    while let current = currentIndex, current < lineEnd {
      characterWidth = graphics.size(of: String(stateString[current]), wrapping: .none).width

      if point.x > currentX + characterWidth / 2 {
        currentX += characterWidth
      } else {
        return currentIndex
      }

      currentIndex = state.text.index(after: current)
    }

    if let currentIndex = currentIndex {
      if isLastLine { return currentIndex }
      return min(currentIndex, stateString.index(before: lineEnd))
    }

    return nil
  }

  ///
  /// Returns the line rect and the index line index of the line nearest `point`.
  ///
  public func lineRectNearest(point: CGPoint, range: Range<Int>? = nil) -> (Int, CGRect)? {
    if lineRectCache.isEmpty { return nil }

    let searchRange = range ?? 0..<lineRectCache.count

    if searchRange.startIndex == searchRange.endIndex {
      let index = max(0, searchRange.startIndex - 1)
      return (index, lineRectCache[index])
    }

    // Calculate where to split the array.
    let midIndex = searchRange.lowerBound + (searchRange.upperBound - searchRange.lowerBound) / 2
    let midValue = lineRectCache[midIndex]

    if midValue.origin.y < point.y
      && midValue.origin.y + midValue.height + interlineSpacing > point.y {
      return (midIndex, midValue)
    }

    // Is the search key in the left half?
    if midValue.origin.y > point.y {
      return lineRectNearest(point: point, range: searchRange.lowerBound ..< midIndex)
      // Is the search key in the right half?
    } else if midValue.origin.y < point.y {
      return lineRectNearest(point: point, range: midIndex + 1 ..< searchRange.upperBound)
    } else {
      return (midIndex, midValue)
    }
  }

  func wordIndicesNearest(index: String.Index, direction: SearchDirection = .both) -> Range<String.Index> {

    var start = index
    var end = index

    if direction == .left || direction == .both {
      start = self.state.text.indexBeforeWhitespace(startingAt: start)
    }

    if direction == .right || direction == .both {
      end = self.state.text.indexAfterWhitespace(startingAt: end)
    }

    if start < end {
      return start..<end
    }

    return end..<start
  }

  func rectOfIndicesWithinSingleLine(_ range: Range<String.Index>) -> CGRect {
    let startLoc = location(forIndex: range.lowerBound)
    let endLoc = location(forIndex: range.upperBound)

    if let rectForLine = lineRect(forIndex: range.lowerBound) {
      return CGRect(x: startLoc.x,
                    y: rectForLine.origin.y,
                    width: endLoc.x - startLoc.x,
                    height: rectForLine.height)
    }

    return CGRect.zero
  }

  ///
  /// Returns the line and column positions matching the supplied offset.  The result is
  /// in UTF8 terms.
  ///
  public func convertOffsetToLinePosition(_ offset: String.Index) -> (line: Int, column: Int)? {

    let utf8Offset = state.text.buffer.utf8.distance(from: state.text.buffer.utf8.startIndex,
                                                     to: offset)
    return convertUTF8OffsetToLinePosition(utf8Offset)
  }

  public func convertUTF8OffsetToLinePosition(_ offset: Int) -> (line: Int, column: Int)? {
    if state.text.numberOfLines == 0 { return  nil }

    let result = state.text.lineCharacterRanges.binarySearch(key: offset..<offset + 1)
      ?? state.text.numberOfLines - 1

    let lineInfo = state.text.lineCharacterRanges[result]

    return (result + 1,
            offset - lineInfo.lowerBound)
  }

  public func convertOffsetToUTF16LinePosition(_ offset: String.Index) -> (line: Int, column: Int)? {
    let utf8Offset = state.text.buffer.utf8.distance(from: state.text.buffer.utf8.startIndex,
                                                     to: offset)
    return convertUTF8OffsetToUTF16LinePosition(utf8Offset)
  }

  public func convertUTF8OffsetToUTF16LinePosition(_ offset: Int) -> (line: Int, column: Int)? {
    if state.text.numberOfLines == 0 { return  nil }

    let result = state.text.lineCharacterRanges.binarySearch(key: offset..<offset)
      ?? state.text.numberOfLines - 1

    let lineInfo = state.text.lineCharacterRanges[result]

    let start = state.text.buffer.utf8.index(state.text.startIndex,
                                             offsetBy: lineInfo.lowerBound)

    guard let startIdx = String.Index(start, within: state.text.buffer.utf16) else {
      return nil
    }

    let utf16LineStart = state.text.buffer.utf16.distance(from: state.text.startIndex,
                                                          to: startIdx)
    let utf8Idx = state.text.buffer.utf8.index(state.text.startIndex,
                                               offsetBy: offset)
    let utf16Offset = state.text.buffer.utf16.distance(from: state.text.startIndex,
                                                       to: utf8Idx)

    return (result + 1,
            utf16Offset - utf16LineStart)
  }

  /// Input handling

  @discardableResult
  override open func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    super.onKeyEvent(keyEvent)
    guard keyEvent.strokeType == .down else { return false }

    if handleArrowKeyEvent(keyEvent) { return true }

    guard !readOnly else { return true }

    if handleDeleteKeyEvent(keyEvent) { return true }

    if let input = keyEvent.characters, let position = position {

      // Defer trigger key handling so that any included edits are applied first.
      defer {
        // If we detect a trigger character, invoke the approprate method
        // so subclasses can react, if needed.
        for triggerKey in triggerKeyEvents {
          if keyEvent.characters == triggerKey.characters
            && keyEvent.modifiers == triggerKey.modifiers {
            didPress(triggerKey: triggerKey)
            break
          }
        }
      }

      // Just skip all control characters for now.
      if keyEvent.modifiers?.contains(.command) == true
        || keyEvent.modifiers?.contains(.control) == true
        || keyEvent.modifiers?.contains(.function) == true {
        return false
      }

      if let positionIndex = positionIndex {
        insert(text: input, at: positionIndex)
      }
    }

    return true
  }

  ///
  /// Called whenever a trigger key press is detected.  Subclasses must call super.
  ///
  /// - parameter triggerKey: the KeyEvent for the detected trigger key.
  ///
  open func didPress(triggerKey: KeyEvent) {
    onTriggerKey?(triggerKey)
  }

  ///
  /// Handles the key event for left, right, up, and down arrow keys.
  /// This method does nothing if the keyEvent is not for an arrow key.
  ///
  /// - returns: true if the event was successfully handled as an arrow key event.
  ///
  func handleArrowKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    guard let position = positionIndex else { return false }

    // Don't blink the caret while moving it.
    caretTimer.suspend(for: caretBlinkSpeed)
    caretOn = true

    switch keyEvent.keyType {
      case .leftArrow:
        removeAllSelections()

        if position == state.text.startIndex { return true }

        if keyEvent.modifiers?.contains(.option) == true {
          let wordIndices = wordIndicesNearest(index: position, direction: .left)
          self.position = state.text.distance(from: state.text.startIndex,
                                              to: wordIndices.lowerBound)
        } else {
          let offset = state.text.index(before: position)
          self.position = state.text.distance(from: state.text.startIndex,
                                              to: offset)
        }

        expectedColumn = nil
        return true
      case .rightArrow:
        removeAllSelections()

        if position == state.text.endIndex { return true }

        if keyEvent.modifiers?.contains(.option) == true {
          let wordIndices = wordIndicesNearest(index: position)
          self.position = state.text.distance(from: state.text.startIndex,
                                              to: wordIndices.upperBound)
        } else {
          let offset = state.text.index(after: position)
          self.position = state.text.distance(from: state.text.startIndex,
                                              to: offset)
        }

        expectedColumn = nil
        return true
      case .upArrow:
        removeAllSelections()

        if expectedColumn == nil {
          expectedColumn = currentColumn
        }

        if let line = lineNumber(containing: position) {
          movePosition(toLine: line - 1)
          return true
        }
        return false
      case .downArrow:
        removeAllSelections()

        if expectedColumn == nil {
          expectedColumn = currentColumn
        }

        if let line = lineNumber(containing: position) {
          movePosition(toLine: line + 1)
          return true
        }
        return false
      default:
        break
    }

    return false
  }

  ///
  /// Clears any selections.  This has no affect on the text content.
  ///
  func removeAllSelections() {
    selectedRange = nil
    selectedLineRects.removeAll()
  }

  ///
  /// Inserts `text` at `index`.
  ///
  /// - parameter text: the text to be inserted.
  /// - parameter index: the index at which to insert the text.
  ///
  open func insert(text: String, at index: String.Index) {
    var newPosition = index
    let lineCount = state.text.numberOfLines

    var insertedText = text
    insertedText.makeNativeUTF8IfNeeded()

    if deleteSelection() {
      newPosition = self.positionIndex ?? index
    }

    let characters = insertedText.replacingOccurrences(of: "\r",
                                                       with: "\n")
      // TODO Temporary fix
      .replacingOccurrences(of: "\t", with: "  ")

    guard characters.count > 0 else { return }

    state.text.insert(characters, at: newPosition)

    if state.text.numberOfLines != lineCount {
      // TODO this is far too expensive here.
      resizeToFitContent()
    } else if let currentLine = currentLine  {
      resizeToFitContent(onLine: currentLine)
    }

    self.position = min(state.text.count,
                        characters.count + (position ?? 0))

    if state.text.numberOfLines != lineCount {
      window.redrawManager.redraw(view: self)
    }

    didInsert(text: characters, at: newPosition)
  }

  ///
  /// This method is called after some text has been inserted.  The default implementation
  /// does nothing.
  ///
  /// - parameter text: the text that was inserted.
  /// - parameter index: the index at which the text was inserted.
  ///
  open func didInsert(text: String, at index: String.Index) {}

  ///
  /// Handles the key event for delete.
  /// This method does nothing if the keyEvent is not for the delete key.
  ///
  /// - returns: true if the event was successfully handled as a delete key event.
  ///
  func handleDeleteKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    guard keyEvent.keyType == .delete else { return false }

    if deleteSelection() {
      window.redrawManager.redraw(view: self)
      return true
    }

    // We still return true here because this was a delete key press, there's just no work
    // for us to do--we don't want our caller to try to intrepet it as an insert of anything
    // like that.
    guard let position = positionIndex,
      position != state.text.startIndex else { return true }

    let lineCount = state.text.numberOfLines
    let range: Range<String.Index>
    let deletePosition: String.Index
    let postDeletionPosition: String.Index

    // Forwards delete.
    if keyEvent.modifiers?.contains(.function) == true {
      deletePosition = state.text.index(after: position)
      range = position..<deletePosition

      // This line is a hack because with a forwards delete the caret position
      // doesn't change, but the line only gets redrawn when it does.  In order to trigger
      // that change, set an incorrect position here.
      self.position = state.text.distance(from: state.text.startIndex, to: deletePosition)

      postDeletionPosition = position
    }
      // Backwards delete.
    else {
      deletePosition = state.text.index(before: position)
      range = deletePosition..<position
      postDeletionPosition = deletePosition
    }

    willRemove(range: range)
    state.text.removeSubrange(range)
    self.position = state.text.distance(from: state.text.startIndex, to: postDeletionPosition)
    didRemove(range: range)

    if state.text.numberOfLines != lineCount {
      // TODO resizeToFitContent blows away all line caches etc.
      // Calling this here just assumes the worst case scenario,
      // but we can be much smarter than that.
      resizeToFitContent()
      window.redrawManager.redraw(view: self)
    } else if let currentLine = currentLine {
      resizeToFitContent(onLine: currentLine)
    }

    return true
  }

  ///
  /// Removes all text from the view.
  ///
  public func deleteAll() {
    selectedRange = nil
    selectedLineRects = [:]
    position = 0

    let range = state.text.startIndex..<state.text.endIndex
    willRemove(range: range)
    state.text.removeSubrange(range)
    didRemove(range: range)
  }

  ///
  /// Deletes the currently selected text.  This method does nothing if not text is
  /// selected.
  ///
  /// - returns: a boolean indicating whether or not some text was deleted.
  ///
  @discardableResult
  open func deleteSelection() -> Bool {
    guard !readOnly else { return false }

    if let selectedRange = selectedRange {
      self.selectedRange = nil
      selectedLineRects = [:]

      position = state.text.distance(from: state.text.startIndex,
                                     to: selectedRange.lowerBound)

      willRemove(range: selectedRange)
      state.text.removeSubrange(selectedRange)
      didRemove(range: selectedRange)
      forceRedraw()
      return true
    }

    return false
  }

  ///
  /// This method is called before some text is removed.  The default implementation
  /// does nothing.
  ///
  /// - parameter range: the range of text that will be removed.
  ///
  open func willRemove(range: Range<String.Index>){}

  ///
  /// This method is called after some text has been removed.  The default implementation
  /// does nothing.
  ///
  /// - parameter range: the range of text that was removed.
  ///
  open func didRemove(range: Range<String.Index>){}

  ///
  /// Moves the current `position` to the same position on the given line.
  ///
  func movePosition(toLine: Int) {
    guard let position = positionIndex, toLine > 0, toLine <= numberOfLines else { return }

    let currentLine = lineNumber(containing: position) ?? 1
    let isLastLine = toLine == numberOfLines

    guard let lineStartIndex = state.text.rangeOfLine(currentLine)?.lowerBound,
      let toLineIndices = state.text.rangeOfLine(toLine) else { return }

    let positionOnLine = expectedColumn ?? state.text.distance(from: lineStartIndex,
                                                               to: position)

    let lineLength = state.text.distance(from: toLineIndices.lowerBound,
                                         to: toLineIndices.upperBound)

    if positionOnLine >= lineLength {
      if isLastLine {
        self.position = state.text.distance(from: state.text.startIndex,
                                            to: toLineIndices.upperBound)
      } else {
        let offset = state.text.index(before: toLineIndices.upperBound)
        self.position = state.text.distance(from: state.text.startIndex, to: offset)
      }
    } else {
      let offset = state.text.index(toLineIndices.lowerBound, offsetBy: positionOnLine)
      self.position = state.text.distance(from: state.text.startIndex, to: offset)
    }
  }

  open override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    background.color = .textAreaBackgroundColor
    textColor = .textColor
  }
}

extension TextAreaView {

  ///
  /// The range of a cut/copy/paste operation.  This returns the range of selected
  /// text, or if there is no selection, the range of the current line.  If there is
  /// no current line, nil is returned.
  ///
  private func affectedRange() -> Range<String.Index>? {
    if let selectedRange = selectedRange {
      return selectedRange
    } else if let currentLine = currentLine {
      // Select the whole line.
      select(line: currentLine)
      return state.text.rangeOfLine(currentLine)
    }

    return nil
  }

  ///
  /// Deletes the currently selected text and adds it to the clipboard.
  ///
  public func cut() {
    copy()
    if let range = affectedRange() {
      selectedRange = range
      deleteSelection()
    }
  }

  ///
  /// Copies the currently selected text to the clipboard.
  ///
  public func copy() {
    if let range = affectedRange() {
      let copiedText = state.text[range]
      Clipboard.general.add(string: String(copiedText))
    }
    window.redrawManager.redraw(view: self)
  }

  ///
  /// Inserts the contents of the clipboard.
  ///
  public func paste() {
    guard !readOnly else { return }

    if let position = positionIndex, let text = Clipboard.general.peek() {
      insert(text: text, at: position)
    }
  }

  ///
  /// Selects all the text in the text area.
  ///
  public func selectAll() {
    select(range: state.text.range)
  }
}

extension TextAreaView {

  ///
  /// If inside a ScrollView, scrolls the text area to the specified line according to the behaviour
  /// described by `position`.
  ///
  /// - parameter line: the line to scroll to.
  /// - parameter position: the position `line` should appear at within the visible portion
  ///  of the view.  Defaults to `middle`.
  ///
  public func scroll(toLine line: Int, position: VerticalScrollPosition = .middle) {
    guard let scrollView = embeddingScrollView,
      let rect = lineRectCache[safe: line - 1] else { return }

    var yPos = -rect.origin.y    

    switch position {
      case .middle:
        if yPos < -scrollView.frame.height {
          yPos += scrollView.frame.height / 2
        }
        else if frame.height > scrollView.frame.height {
          yPos = -rect.origin.y / 2
      }
      case .bottom:
        yPos += scrollView.frame.height - rect.height
      default: break // top
    }

    scrollView.scroll(to: CGPoint(x: scrollView.xOffsetTotal, y: yPos))
  }
  
  ///
  /// If inside a ScrollView, scrolls the text area to the specified column according to the behaviour
  /// described by `position`.  Note that this function does not scroll to `line`, it merely uses `line`
  /// to locate the column information.
  ///
  /// - parameter column: the column to scroll to.
  /// - parameter line: the line on which the column appears.
  /// - parameter position: the position `column` should appear at within the visible portion
  ///  of the view.  Defaults to `middle`.
  ///
  public func scroll(toColumn column: Int, onLine line: Int, position: HorizontalScrollPosition = .center) {
    guard let scrollView = embeddingScrollView,
          let lineRange = state.text.rangeOfLine(line) else { return }
    
    guard state.text.distance(from: lineRange.lowerBound,
                              to: lineRange.upperBound) >= column else { return }
    
    let columnPoint = location(forIndex: state.text.index(lineRange.lowerBound, offsetBy: column))
    
    var xPos = columnPoint.x
    
    switch position {
    case .center:
      if xPos < scrollView.frame.width / 2 {
        xPos = 0
      }
      else {
        xPos = (scrollView.frame.width / 2) - columnPoint.x
      }
    case .right:
      xPos = scrollView.frame.width - xPos
    case .left:
      xPos = -xPos
    }
    
    scrollView.scroll(to: CGPoint(x: xPos, y: scrollView.yOffsetTotal))
  }

  ///
  /// If `line` is offscreen, this function will scroll to it (making the minimal scroll movements),
  /// and return true.  Otherwise this function does nothing but return false.
  ///
  @discardableResult
  func scrollToLineIfOffscreen(_ line: Int) -> Bool {
    let linesRange = visibleLines.dropFirst()
    if !linesRange.contains(line) {
      if line > linesRange.lowerBound {
        scroll(toLine: line, position: .bottom)
      } else {
        scroll(toLine: line, position: .top)
      }
      return true
    }
    return false
  }
  
  ///
  /// If `column` is offscreen, this function will scroll to it (making the minimal scroll movements),
  /// and return true.  Otherwise this function does nothing but return false.
  ///
  @discardableResult
  func scrollToColumnIfOffscreen(_ column: Int, onLine line: Int) -> Bool {
    if !visibleColumns(onLine: line).contains(column) {
     scroll(toColumn: column, onLine: line, position: .right)
     return true
    }
    return false
  }

}
