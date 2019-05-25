//
// Created by pmacro on 14/01/17.
//

import Foundation

///
/// Displays read-only text.
///
open class Label: View, TextDisplay {
  
  /// The text to display.
  public var text: String?
  
  /// The colour of the label's text.
  public var textColor: Color = .darkTextColor {
    didSet {
      userChangedDefaultTextColor = true
    }
  }
  
  /// This is used to track whether or not it's safe for us to automatically
  /// change the text color for the user whenever the Appearance changes.
  /// We'll only do it if the user has not updated the text color.
  private var userChangedDefaultTextColor = false
  
  /// The font to use for the label.
  public var font: Font = Font(size: 12, family: "Helvetica")
  
  /// The horizontal text layout behaviour.
  public var horizontalArrangement: HorizontalTextArrangement = .left
  
  /// The vertical text layout behaviour.
  public var verticalArrangement: VerticalTextArrangement = .top

  required public init() {
    super.init()
    acceptsMouseEvents = false
    background.color = .clear
  }
  
  ///
  /// Creates a label populated with `text`.
  ///
  convenience public init(text: String) {
    self.init()
    self.text = text
  }
  
  ///
  /// Draw the label
  ///
  public override func draw(rect: CGRect) {
    super.draw(rect: rect)

    guard let text = text else {
      return
    }

    graphics.set(color: textColor)
    graphics.set(font: font)
    graphics.draw(text: text,
                  inRect: rect,
                  horizontalArrangement: horizontalArrangement,
                  verticalArrangement: verticalArrangement,
                  with: nil,
                  wrapping: .none)
  }
  
  ///
  /// The properties of the label that can be animated.
  ///
  override public func generateAnimatableProperties<T>(in properties: AnimatableProperties<T>) where T: Label {
    super.generateAnimatableProperties(in: properties)
    properties.add(\.font)
    properties.add(\.textColor)
  }
  
  open override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    
    if !userChangedDefaultTextColor {
      textColor = style == .light ? .darkTextColor : .lightTextColor
      userChangedDefaultTextColor = false
    }
  }
}
