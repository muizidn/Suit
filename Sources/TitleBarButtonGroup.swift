//
//  ButtonGroup.swift
//  suit
//
//  Created by pmacro  on 29/05/2018.
//

import Foundation

///
/// A view that includes window buttons.
///
internal class TitleBarButtonGroup: View {
  
  required init() {
    super.init()
    flexDirection = .row
    justifyContent = .spaceBetween
    
    let closeButton = Button()
    closeButton.width = 18~
    closeButton.height = 18~
    let closeImage = Image(filePath: resolveRelativeImagePath("Images/close.png"))
    closeButton.set(image: closeImage)
    closeButton.imageView.width = 10~
    closeButton.imageView.height = 10~
    closeButton.imageView.useImageAsMask = true
    closeButton.imageView.tintColor = .white
    closeButton.alignContent = .center
    closeButton.justifyContent = .center
    closeButton.changesStateOnRollover = true

    var normalBackground = closeButton.background
    normalBackground.color = 0xE13C0D
    normalBackground.cornerRadius = 20

    var focusedBackground = normalBackground
    focusedBackground.color = focusedBackground.color.lighter()

    var pressedBackground = normalBackground
    pressedBackground.color = focusedBackground.color.darker()

    closeButton.set(background: normalBackground, forState: .unfocused)
    closeButton.set(background: focusedBackground, forState: .focused)
    closeButton.set(background: pressedBackground, forState: .pressed)

    closeButton.onPress = { [weak self] in
      self?.window.close()
    }
    
    let zoomButton = Button()
    zoomButton.width = 18~
    zoomButton.height = 18~

    let zoomImage = Image(filePath: resolveRelativeImagePath("Images/zoom.png"))
    zoomButton.set(image: zoomImage)
    zoomButton.imageView.width = 10~
    zoomButton.imageView.height = 10~
    zoomButton.imageView.useImageAsMask = true
    zoomButton.imageView.tintColor = .white
    zoomButton.alignContent = .center
    zoomButton.justifyContent = .center
    zoomButton.changesStateOnRollover = true

    normalBackground = zoomButton.background
    normalBackground.cornerRadius = 18

    focusedBackground = normalBackground
    focusedBackground.color = .darkGray

    pressedBackground = normalBackground
    pressedBackground.color = .darkerGray

    zoomButton.set(background: normalBackground, forState: .unfocused)
    zoomButton.set(background: focusedBackground, forState: .focused)
    zoomButton.set(background: pressedBackground, forState: .pressed)

    zoomButton.onPress = { [weak self] in
      self?.window.zoom()
    }

    let minimiseButton = Button()
    minimiseButton.width = 18~
    minimiseButton.height = 18~

    let minimiseImage = Image(filePath: resolveRelativeImagePath("Images/minimize.png"))
    minimiseButton.set(image: minimiseImage)
    minimiseButton.imageView.width = 10~
    minimiseButton.imageView.height = 10~
    minimiseButton.imageView.useImageAsMask = true
    minimiseButton.imageView.tintColor = .white
    minimiseButton.alignContent = .center
    minimiseButton.justifyContent = .center
    minimiseButton.changesStateOnRollover = true
    
    minimiseButton.set(background: normalBackground, forState: .unfocused)
    minimiseButton.set(background: focusedBackground, forState: .focused)
    minimiseButton.set(background: pressedBackground, forState: .pressed)

    minimiseButton.onPress = { [weak self] in
      self?.window.minimize()
    }
    
    add(subview: closeButton)
    add(subview: zoomButton)
    add(subview: minimiseButton)
  }
  
  private func resolveRelativeImagePath(_ path: String) -> String {
    return URL(fileURLWithPath: #file + "/../../" + path)
      .standardizedFileURL.path
  }  
}
