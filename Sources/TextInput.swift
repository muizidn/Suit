//
//  TextInput.swift
//  Suit
//
//  Created by pmacro  on 27/03/2019.
//

import Foundation

///
/// A view that allows for single-line text input.
///
public class TextInputView: TextAreaView {
  
  public var submitsOnEnter: Bool = true
  public var submitsOnAnyKeyPress: Bool = false
  public var rejectedKeys: [KeyType]?
  
  public typealias OnSubmit = (_ text: String) -> Void
  public var onSubmit: OnSubmit?
  
  public required init() {
    super.init()
    font = .ofType(.system, category: .smallMedium)
    renderer.showGutter = true
    renderer.gutterWidth = 5
    renderer.indicatesCurrentLine = false
    renderer.showLineNumbersInGutter = false

    background.borderSize = 0.25
    background.borderColor = .darkGray
    readOnly = false
  }
  
  public override func didAttachToWindow() {
    super.didAttachToWindow()
    position = 0
    
    let enterKey = createPlatformKeyEvent(characters: "\n",
                                          strokeType: .down,
                                          modifiers: [],
                                          keyType: .enter)
    
    let returnKey = createPlatformKeyEvent(characters: "\r",
                                           strokeType: .down,
                                           modifiers: [],
                                           keyType: .return)
    triggerKeyEvents = [enterKey, returnKey]
  }
  
  public override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    
    background.color = .textAreaBackgroundColor
  }
  
  override open func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    
    if rejectedKeys?.contains(keyEvent.keyType) == true { return false }
    
    if keyEvent.strokeType == .down {
      if submitsOnEnter, keyEvent.keyType == .enter
                         || keyEvent.keyType == .return
      {
        onSubmit?(state.text.buffer)
        return true
      }
    }
    
    let result = super.onKeyEvent(keyEvent)
    
    if submitsOnAnyKeyPress,
      keyEvent.strokeType == .down,
      keyEvent.keyType.isTextInput || keyEvent.keyType == .delete {
      onSubmit?(state.text.buffer)
    }
    
    return result
  }
}
