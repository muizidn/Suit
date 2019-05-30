//
//  DividerComponent.swift
//  Suit
//
//  Created by pmacro  on 18/02/2019.
//

import Foundation

///
/// The possible divider orientations.
///
public enum DividerOrientation {
  case vertical
  case horizontal
}

///
/// A component that acts as a divider between other components, providing callbacks for
/// the grabbing and release of the divider, allowing for resize implementations etc.
///
public class DividerComponent: Component {
  
  public let orientation: DividerOrientation
  public var onGrab: ((_ horizontalSize: CGFloat) -> Void)?
  public var onRelease: (() -> Void)?

  required public init(orientation: DividerOrientation) {
    self.orientation = orientation
    super.init()
  }
  
  override public func loadView() {
    let grabberView = GrabberView()
    grabberView.orientation = orientation
    grabberView.onGrab = { [weak self] change in
      if let grabAction = self?.onGrab {
        grabAction(change)
        self?.view.window.rootView.invalidateLayout()
        self?.view.window.redrawManager.redraw(view: self!.view.window.rootView)
      }
    }
    
    grabberView.onRelease = onRelease
    
    view = grabberView
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    if orientation == .horizontal {
      view.height = 0.5~
      view.width = 100%
    } else {
      view.height = 100%
      view.width = 0.5~
    }
    
    view.background.color = Color.lightGray
  }
}

class GrabberView: View {
  
  var orientation: DividerOrientation = .horizontal
  var lastDragPoint: CGPoint?
  var onGrab: ((_ horizontalSize: CGFloat) -> Void)?
  var onRelease: (() -> Void)?

  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    if super.onPointerEvent(pointerEvent) { return true }
    
    switch pointerEvent.type {
    case .click:
      window.lockFocus(on: self)
      lastDragPoint = pointerEvent.location
    case .release:
      lastDragPoint = nil
      onRelease?()
    case .exit:
      window.releaseFocus(on: self)
      Cursor.shared.pop()
    case .drag:
      lastDragPoint = lastDragPoint ?? pointerEvent.dragStartingPoint
      
      guard let lastDragPoint = lastDragPoint else { return false }
      
      let diff: CGFloat
      
      if orientation == .vertical {
       diff = pointerEvent.location.x - lastDragPoint.x
      } else {
        diff = pointerEvent.location.y - lastDragPoint.y
      }
      
      onGrab?(diff)
      
      self.lastDragPoint = pointerEvent.location
    case .enter:
      window.lockFocus(on: self)
      Cursor.shared.push(type: orientation == .vertical
                                            ? .resizeLeftRight
                                            : .resizeUpDown)
    default:
      return false
    }
    
    return true
  }
}
