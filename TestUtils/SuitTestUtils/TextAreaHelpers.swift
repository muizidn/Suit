//
//  TextAreaHelpers.swift
//  SuitTests
//
//  Created by pmacro on 09/02/2019.
//

import Foundation
@testable import Suit

public var window: Window = {
  let _window = Window(rootComponent: CompositeComponent(), frame: .zero)
  createApplication(with: _window)
  _window.graphics = TestGraphics()
  return _window
}()

public func createTextArea() -> TextAreaView {
  let view = createView(ofType: TextAreaView.self)
  view.resizeToFitContent()
  view.readOnly = false
  return view
}

public func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map { _ in letters.randomElement()! })
}

public func randomString(numberOfLines lineCount: Int, lineLength: Int) -> String {
  let lineContent = randomString(length: lineLength)
  var content = ""
  for i in 0..<lineCount {
    content += lineContent
    
    if i != lineCount - 1 {
      content += "\n"
    }
  }
  
  return content
}

public func populate(textArea: TextAreaView,
                     withNumberOfLines lineCount: Int,
                     lineLength: Int = 10) {

  populate(textArea: textArea, with: randomString(numberOfLines: lineCount,
                                                  lineLength: lineLength))
}

public func populate(textArea: TextAreaView, with content: String) {
  var start = Date()
  textArea.state.text = StringDocument(string: content)
  print("Buffer creation took: \(Date().timeIntervalSince(start))s")

  start = Date()
  textArea.resizeToFitContent()
  print("resizeToFitContent took: \(Date().timeIntervalSince(start))s")
}
