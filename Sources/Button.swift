//
//  Button.swift
//  Suit
//
//  Created by pmacro on 13/01/2017.
//
//

import Foundation

///
/// Represents an additonal border around a button.
///
private struct ButtonHighlightRing {
  public init() {}

  public var size: Double = 0
  public var color = Color.white
  public var cornerRadius: Double = 0
}

///
/// A Button that can be a particular `ButtonType` or configured manually.
/// The `onPress` callback can be used to be informed of a button press.
///
open class Button: View {
  
  /// The button's title.
  public var title: String? {
    didSet {
      titleLabel.text = title
      titleLabel.width = .init(unit: .auto, value: .nan)
      titleLabel.flex = 1
    }
  }

  /// When true, the button changes its state between .focused and .unfocused when the pointer
  /// enters and exits the button.  This property is false by default.  Setting the property
  /// to false effectively disables 'rollovers' for the button.
  public var changesStateOnRollover = false

  // Used internally to recieve information about a button press before
  // the callback.
  internal var prePress: (() -> Void)?
  public var onPress: (() -> Void)?

  ///
  /// The different types of button.
  ///
  public enum ButtonType {
    case `default`
    case titleBarButton
    case rounded
  }

  ///
  /// The states a button can be in.
  ///
  public enum ButtonState {
    case unfocused
    case focused
    case pressed
  }

  /// The current button state.
  var state: ButtonState = .unfocused

  /// The image to be displayed when the button is unfocused.
  var unfocusedImage: Image?
  
  /// The image to be displayed when the button is focused.
  var focusedImage: Image?
  
  /// The image to be displayed when the button is pressed.
  var pressedImage: Image?
  
  /// The type of button used as this button's template.
  private (set) public var type: ButtonType = .default
  
  /// The foreground color when this button is not focused.
  var unfocusedForegroundColor: Color = Color.black
  
  /// The foreground color when this button is focused.
  var focusedForegroundColor: Color = Color.black
  
  /// The foreground color when this button is pressed.
  var pressedForegroundColor: Color = Color.black

  /// The background color when this button is not focused.
  var unfocusedBackground: Background?
  
  /// The background color when this button is focused.
  var focusedBackground: Background?
  
  /// The background color when this button is pressed.
  var pressedBackground: Background?

  /// The highlight ring when this button is not focused.
  fileprivate var unfocusedHighlightRing: ButtonHighlightRing?
  
  /// The highlight ring when this button is focused.
  fileprivate var focusedHighlightRing: ButtonHighlightRing?
  
  /// The highlight ring when this button is pressed.
  fileprivate var pressedHighlightRing: ButtonHighlightRing?
  
  /// The image view that is rendered inside the button.  You can configure this view
  /// like any other, adjusting its layout, background etc.
  public var imageView = ImageView()
  
  /// The label that displays the button's text.
  public var titleLabel: Label

  ///
  /// Creates a button of the specified type.
  ///
  public init(ofType type: ButtonType) {
    self.titleLabel = Label()

    super.init()
    self.type = type
    flexDirection = .row
    alignItems = .center

    isDraggable = false
    
    addChildren()
  }
  
  ///
  /// Creates a button of the default type.
  ///
  public required init() {
    self.titleLabel = Label()
    super.init()
    background.color = .clear
    flexDirection = .row
    alignItems = .center
    
    isDraggable = false
    
    addChildren()
  }
  
  ///
  /// The button comes preconfigured with a label and an image view.  This function
  /// sets those up with some sensible defaults.
  ///
  private func addChildren() {
    if imageView.superview == nil {
      add(subview: imageView)
      imageView.width = 0~
      imageView.height = 100%
    }
    
    if titleLabel.superview == nil {
      add(subview: titleLabel)
      titleLabel.height = 100%
      titleLabel.width = 0~
      titleLabel.verticalArrangement = .center
      titleLabel.horizontalArrangement = .left
    }
  }

  ///
  /// Update the appearance of the button for the active style.
  ///
  open override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
   
    switch type {
      case .titleBarButton:
        titleLabel.horizontalArrangement = .center
        titleLabel.verticalArrangement = .center

        var buttonBackground = Background()

        #if os(macOS)
        width = 40~
        height = 22~
        set(foregroundColor: .textColor, forState: .unfocused)
        set(foregroundColor: .textColor, forState: .pressed)
        set(foregroundColor: .textColor, forState: .focused)

        buttonBackground.color = style == .light ? .lighterGray : .darkGray
        buttonBackground.cornerRadius = 8
        buttonBackground.borderSize = 0.1
        buttonBackground.borderColor = .black
        #else
        width = 50~
        height = 30~

        set(foregroundColor: .lightTextColor, forState: .unfocused)
        set(foregroundColor: .lightTextColor, forState: .pressed)
        set(foregroundColor: .lightTextColor, forState: .focused)

        var highlightRing = ButtonHighlightRing()
        highlightRing.size = 0.1
        highlightRing.cornerRadius = 10
        highlightRing.color = .white

        set(highlightRing: highlightRing, forState: .unfocused)
        highlightRing.color = .lightGray
        set(highlightRing: highlightRing, forState: .focused)
        highlightRing.color = .highlightedCellColor
        set(highlightRing: highlightRing, forState: .pressed)

        buttonBackground.color = .clear
        buttonBackground.cornerRadius = 10
        buttonBackground.borderSize = 0.5
        buttonBackground.borderColor = 0x222222
        #endif

        focusedBackground = buttonBackground
        unfocusedBackground = buttonBackground

        buttonBackground.color = style == .light ? .darkGray : .lightGray
        pressedBackground = buttonBackground
      case .rounded:
        set(foregroundColor: .textColor, forState: .unfocused)
        set(foregroundColor: .white, forState: .pressed)
        set(foregroundColor: .textColor, forState: .focused)
        
        var background = Background()
        background.borderSize = 0.4
        background.cornerRadius = 8
        background.borderColor = style == .light ? .darkGray : .black
        background.color = style == .light ? .white : .darkGray
        
        titleLabel.font = .ofType(.system, category: .medium)
        titleLabel.horizontalArrangement = .center
        titleLabel.verticalArrangement = .center
        unfocusedBackground = background
        focusedBackground = background

        var pressed = background
        pressed.color = .highlightedCellColor
        pressedBackground = pressed
      case .default:
        break
    }

  }

  ///
  /// Sets the button's image for a particular state.  If no state is provided, the image
  /// is used for all states.
  ///
  open func set(image: Image, forState state: ButtonState? = nil) {
    // Just some defaults.
    imageView.width = 12~
    imageView.aspectRatio = 1
    
    switch (state) {
      case .focused?:
        focusedImage = image
      case .unfocused?:
        unfocusedImage = image
      case .pressed?:
        pressedImage = image
      default:
        focusedImage = image
        unfocusedImage = image
        pressedImage = image
    }
  }

  ///
  /// Sets the button's foreground color for a particular state.  If no state is provided,
  /// the color is used for all states.
  ///
  open func set(foregroundColor: Color, forState state: ButtonState?) {
    switch (state) {
      case .focused?:
        focusedForegroundColor = foregroundColor
      case .unfocused?:
        unfocusedForegroundColor = foregroundColor
      case .pressed?:
        pressedForegroundColor = foregroundColor
      default:
        focusedForegroundColor = foregroundColor
        unfocusedForegroundColor = foregroundColor
        pressedForegroundColor = foregroundColor
    }
  }

  ///
  /// Sets the button's background color for a particular state.  If no state is provided,
  /// the color is used for all states.
  ///
  open func set(background backgroundConfiguration: Background, forState state: ButtonState?) {
    switch (state) {
      case .focused?:
        focusedBackground = backgroundConfiguration
      case .unfocused?:
        unfocusedBackground = backgroundConfiguration
      case .pressed?:
        pressedBackground = backgroundConfiguration
      default:
        focusedBackground = backgroundConfiguration
        unfocusedBackground = backgroundConfiguration
        pressedBackground = backgroundConfiguration
    }
  }

  
  fileprivate func set(highlightRing: ButtonHighlightRing, forState state: ButtonState) {
    switch (state) {
      case .focused:
        focusedHighlightRing = highlightRing
      case .unfocused:
        unfocusedHighlightRing = highlightRing
      case .pressed:
        pressedHighlightRing = highlightRing
    }
  }
  
  ///
  /// Draw the button, ensuring the correct values are used for the current button state.
  ///
  public override func draw(rect: CGRect) {
    super.draw(rect: rect)

    switch (state) {
      case .unfocused:
        imageView.image = unfocusedImage
        titleLabel.textColor = unfocusedForegroundColor
      case .focused:
        imageView.image = focusedImage
        titleLabel.textColor = focusedForegroundColor
      case .pressed:
        imageView.image = pressedImage
        titleLabel.textColor = pressedForegroundColor
    }
  }

  ///
  /// Draw the background for the current button state.
  ///
  public override func drawBackground(rect: CGRect) {
    let original = background
    let highlightRing: ButtonHighlightRing?

    switch (state) {
      case .unfocused:
        background = unfocusedBackground ?? background
        highlightRing = unfocusedHighlightRing
      case .focused:
        background = focusedBackground ?? background
        highlightRing = focusedHighlightRing
      case .pressed:
        background = pressedBackground ?? background
        highlightRing = pressedHighlightRing
    }

    super.drawBackground(rect: rect)
    background = original

    guard let ring = highlightRing else { return }

    graphics.lineWidth = ring.size
    let inset = CGFloat(background.borderSize + ring.size + 1)
    graphics.draw(roundedRectangle: rect.insetBy(dx: inset, dy: inset),
                  cornerRadius: ring.cornerRadius)
    graphics.set(color: ring.color)
    graphics.stroke()
  }
  
  ///
  /// Handle pointer events inside the button.
  ///
  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    let wasConsumed = super.onPointerEvent(pointerEvent)

    if wasConsumed {
      return wasConsumed
    }

    if isDraggingInView {
      state = .unfocused
      return wasConsumed
    }

    let originalState = state

    switch (pointerEvent.type) {
      case .click:
        state = .pressed
        window.lockFocus(on: self)

      // We don't want a button being dragged to drag the parent view, i.e. the titlebar.
      case .release:
        if hitTest(point: pointerEvent.location) && state == .pressed {
          state = .focused
          window.lockFocus(on: self)
          press()
        } else {
          // We don't count this as a button press if the pointer was released away from the button.
          state = .unfocused
          window.releaseFocus(on: self)
        }
      case .enter:
        window.lockFocus(on: self)
        Cursor.shared.push(type: .arrow)
        if changesStateOnRollover {
          state = .focused
        }
      case .exit:
        window.releaseFocus(on: self)
        Cursor.shared.pop()
        if changesStateOnRollover {
          state = .unfocused
        }
      case .drag:
        // Eat drags since we don't want the button to drag draggable parent views.
        return true
      default:
        break
    }

    if state != originalState {
      window.redrawManager.redraw(view: self)
    }

    return wasConsumed
  }
  
  ///
  /// Trigger a button press programically.
  ///
  public func press() {
    prePress?()
    onPress?()
  }
}
