//
//  ToggleView.swift
//  Suit
//
//  Created by pmacro on 11/06/2018.
//

import Foundation

///
/// An on/off switch representation of a toggle view.
///
open class ToggleView: View {
  
  public typealias ToggleChangeCallback = (Bool) -> Void
  
  /// Is the toggle in the `on` position.
  open var isOn = false
  
  public var didToggle: ToggleChangeCallback?
  
  let toggleWidth: CGFloat = 40
  let toggleHeight: CGFloat = 20
  let backgroundCornerRadius: Double = 20
  let circleCornerRadius: Double = 30
  
  let touchWidth: CGFloat = 60
  let touchHeight: CGFloat = 30
  let touchBackgroundCornerRadius: Double = 30
  let touchCircleCornerRadius: Double = 45
  
  var togglePosition: CGFloat = 0
  var offBackgroundColor: Color = .white
  var onBackgroundColor: Color = .highlightedCellColor
  
  var toggleAnimation: Animation?
    
  public required init() {
    super.init()
    
    var rectangle = frame
    rectangle.size.height = supportsTouch ? touchHeight : toggleHeight
    rectangle.size.width = supportsTouch ? touchWidth : toggleWidth
    self.frame = rectangle
    
    togglePosition = bounds.origin.x
    
    background.color = offBackgroundColor
    background.borderColor = .lightGray
    background.borderSize = 0.65
    background.cornerRadius = supportsTouch ? touchBackgroundCornerRadius : backgroundCornerRadius
  }
  
  public override func draw(rect: CGRect) {
    super.draw(rect: rect)
    
    var circleRect = rect
    circleRect.size.width *= 0.5
    circleRect.origin.x = togglePosition
    circleRect = circleRect.insetBy(dx: 1, dy: 1)
    
    graphics.lineWidth = 2.5
    graphics.set(color: Color(red: 0, green: 0, blue: 0, alpha: 0.2))
    graphics.draw(roundedRectangle: circleRect,
                      cornerRadius: supportsTouch ? touchCircleCornerRadius : circleCornerRadius)
    graphics.stroke()
    
    graphics.set(color: offBackgroundColor)
    graphics.draw(roundedRectangle: circleRect,
                      cornerRadius: supportsTouch ? touchCircleCornerRadius : circleCornerRadius)
    graphics.fill()
  }
  
  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    if super.onPointerEvent(pointerEvent) {
      return true
    }
    
    if pointerEvent.type == .release {
      didToggle?(!isOn)

      toggleAnimation?.cancel()
      toggleAnimation = animate(duration: 0.2, easing: .quadraticEaseIn, changes: { [weak self] in
        guard let `self` = self else { return }
        if isOn {
          self.togglePosition = bounds.origin.x
          self.background.color = offBackgroundColor
          background.borderSize = 0.65
        } else {
          self.togglePosition = bounds.origin.x + (supportsTouch ? touchWidth : toggleWidth) / 2
          self.background.color = onBackgroundColor
          background.borderSize = 0
        }
      })
      
      isOn = !isOn
      return true
    }
    
    return false
  }
}
