//
//  TitleBar.swift
//  Suit
//
//  Created by pmacro  on 13/01/2017.
//
//

import Foundation

#if os(Linux)
import X11
#endif

///
/// A title bar that provides window buttons and dragging functionality on supported
/// platforms.  In addition, TitleBar exposes `additionalContentView` for the insertion
/// of custom content.
///
public class TitleBar: View {

  var titleLabel: Label?
  public var additionalContentView = View()
  
  #if os(Linux)
  let lightBackgroundGradientStartColor: Color = 0x2f2f2b
  let lightBackgroundGradientEndColor: Color = 0x413f37
  
  let darkBackgroundGradientStartColor: Color = 0x2f2f2b
  let darkBackgroundGradientEndColor: Color = 0x413f37
  #else // macOS
  let lightBackgroundGradientStartColor = Color(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
  let lightBackgroundGradientEndColor = Color(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
  
  let darkBackgroundGradientStartColor = Color(red: 0.160, green: 0.168, blue: 0.172, alpha: 1)
  let darkBackgroundGradientEndColor = Color(red: 0.160, green: 0.168, blue: 0.172, alpha: 1)
  #endif
  
  var backgroundGradientStartColor: Color {
    switch Appearance.current {
      case .light:
        return lightBackgroundGradientStartColor
      case .dark:
        return darkBackgroundGradientStartColor
    }
  }
  
  var backgroundGradientEndColor: Color {
    switch Appearance.current {
    case .light:
      return lightBackgroundGradientEndColor
    case .dark:
      return darkBackgroundGradientEndColor
    }
  }
  
  public var title: String? {
    didSet {
      if let titleLabel = titleLabel {
        titleLabel.text = title
        isDirty = true
        window?.redrawManager.redraw(view: self)
      }
    }
  }
  
  init(title: String? = nil) {
    super.init()
    self.isDraggable = true
    self.clipAtBounds = false
    self.flexDirection = .row
    self.title = title
  }
  
  required public init() {
    super.init()
  }
  
  public override func didAttachToWindow() {
    super.didAttachToWindow()

    if window.drawsSystemWindowButtons {
      
      // On macOS we let the OS draw the system buttons, but since that's outside
      // of Suit layout code, we need to create a spacer for those buttons so other
      // items in the toolbar don't colide with them.
      #if os(macOS)
      let spacer = View()
      spacer.set(margin: 8~, for: .all)
      spacer.width = 53~
      spacer.height = 20~
      add(subview: spacer)
      #else
      let buttons = TitleBarButtonGroup()
      buttons.set(margin: 8~, for: .all)
      buttons.set(margin: 4~, for: .right)
      buttons.set(margin: 4~, for: .left)
      buttons.width = 80~
      buttons.height = 20~
      
      // On Linux, the window buttons are on the right and ordered differently.
      buttons.positionType = .absolute
      buttons.direction = .rightToLeft
      buttons.set(position: 10~, for: .right)
      buttons.set(position: ((window.titleBarHeight / 2) - (15))~, for: .top)

      add(subview: buttons)
      #endif
    }
    
    additionalContentView.height = 100%
    additionalContentView.flex = 1
    additionalContentView.flexDirection = .row
    additionalContentView.alignItems = .center
    additionalContentView.isDraggable = true
    
    add(subview: additionalContentView)
    
    if let title = title {
      titleLabel = Label()
      
      if let titleLabel = titleLabel {
        titleLabel.text = title
        titleLabel.textColor = .textColor
        titleLabel.background.color = Color.clear
        titleLabel.font = Font.ofType(.system, category: .titleBarHeading)
        
        titleLabel.horizontalArrangement = .center
        additionalContentView.add(subview: titleLabel)
      }
    }    
  }
  
  #if os(Linux)

  let menuButton = Button()

  func createMenuButton() -> Button {

    if let menuIconPath = Bundle.main.path(forAsset: "menu", ofType: "png") {
      let image = Image(filePath: menuIconPath)
      menuButton.set(image: image)
      menuButton.imageView.width = 14~
      menuButton.imageView.height = 14~
      menuButton.alignContent = .center
      menuButton.justifyContent = .center
      menuButton.imageView.useImageAsMask = true
      menuButton.imageView.tintColor =  .white
      menuButton.height = 30~
      menuButton.width = 30~
    }

    menuButton.background.cornerRadius = 8
    menuButton.alignSelf = .center
    menuButton.changesStateOnRollover = true

    var focusedBackground = menuButton.background
    focusedBackground.color = .lightGray
    var pressedBackground = menuButton.background
    pressedBackground.color = .gray
    menuButton.set(background: focusedBackground, forState: .focused)
    menuButton.set(background: pressedBackground, forState: .pressed)
    menuButton.alignSelf = .center

    menuButton.set(margin: 110~, for: .right) // Accounts for the system buttons' size.
    add(subview: menuButton)
    return menuButton
  }
  #endif
  
  public override func draw(rect: CGRect) {
    super.draw(rect: rect)
    if background.color.alphaValue == 1 { return }

    graphics.drawGradient(inRect: rect,
                          startColor: backgroundGradientStartColor,
                          stopColor: backgroundGradientEndColor)
    
    let shadowRect = CGRect(x: rect.origin.x,
                            y: rect.height - 0.5,
                            width: rect.width,
                            height: 0.5)
    
    let startShadow = Color(red: 0, green: 0, blue: 0, alpha: 0.5)
    let endShadow = Color(red: 0, green: 0, blue: 0, alpha: 0.2)

    graphics.drawGradient(inRect: shadowRect,
                          startColor: startShadow,
                          stopColor: endShadow)
  }
  
  public override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    titleLabel?.textColor = style == .light ? .darkTextColor : .lightTextColor
  }
  
  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    if super.onPointerEvent(pointerEvent) { return true }
    
    guard pointerEvent.type == .drag, isDraggable else { return false }
    
    #if os(macOS)
      window.macWindow.setFrameOrigin(
          CGPoint(x: window.macWindow.frame.origin.x + pointerEvent.deltaX,
                  y: window.macWindow.frame.origin.y - pointerEvent.deltaY))
    #endif

    #if os(Linux)
      window.move(to: CGPoint(x: window.position.x + pointerEvent.deltaX,
                              y: window.position.y - pointerEvent.deltaY))
    #endif
    return true
  }
}
