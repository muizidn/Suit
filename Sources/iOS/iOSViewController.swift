//
//  File.swift
//  Suit
//
//  Created by pmacro on 02/06/2018.
//

#if os(iOS)

import Foundation
import UIKit

class iOSComponent: UIComponent {
  
  var pointerEventDelegate: MouseEventDelegate?
  var suitContainerView: iOSView!
  
  var kineticScrollingTimer: AnimationTimer?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    suitContainerView.layer.contentsScale = UIScreen.main.scale
    target.addSubview(suitContainerView)
    suitContainerView.frame = target.frame
    suitContainerView.isUserInteractionEnabled = true

    let scrollGesture = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
    suitContainerView.addGestureRecognizer(scrollGesture)
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
    tapGesture.numberOfTapsRequired = 1
    suitContainerView.addGestureRecognizer(tapGesture)
    
    suitContainerView.suitWindow?.windowDidLaunch()
  }
  
  ///
  /// Handles scrolling gestures.  This method includes a fairly basic attempt at implementing kinetic scrolling.
  ///
  @objc func panHandler(_ sender: Any) {
    guard let gestureRecognizer = sender as? UIPanGestureRecognizer else { return }
    
    var event = MouseEvent()
    event.type = .scroll
    event.deltaY = gestureRecognizer.velocity(in: suitContainerView).y / CGFloat(AnimationFPS)
    event.deltaX = gestureRecognizer.velocity(in: suitContainerView).x / CGFloat(AnimationFPS)
    kineticScrollingTimer?.stop()
    
    event.location = gestureRecognizer.location(in: suitContainerView)
    _ = pointerEventDelegate?.onPointerEvent(event)
    suitContainerView.layer.setNeedsDisplay()
    
    // Create a timer that synthesizes scroll events that decrease the scrolling movement over time, giving
    // the effect that the scrolling slows-to-a-stop.
    let start = Date()
    kineticScrollingTimer = iOSAnimationTimer.create()

    kineticScrollingTimer?.callback = { [weak self] in
      guard let `self` = self else { return }
      let runningTime = Date().timeIntervalSince(start)
      var syntheticEvent = MouseEvent()
      syntheticEvent.type = .scroll
      
      syntheticEvent.deltaY = event.deltaY / CGFloat(1 + (0.1 * (runningTime)))
      syntheticEvent.deltaX = event.deltaX / CGFloat(1 + (0.1 * runningTime))

      syntheticEvent.location = event.location
      _ = self.pointerEventDelegate?.onPointerEvent(syntheticEvent)
      self.suitContainerView.layer.setNeedsDisplay()
        
      if abs(syntheticEvent.deltaY) < 0.1 {
        self.kineticScrollingTimer?.stop()
      }
        
      event = syntheticEvent
    }
    kineticScrollingTimer?.start()
  }
  
//  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//    super.touchesCancelled(touches, with: event)
//
//    var pointerEvent = MouseEvent()
//    pointerEvent.type = .release
//    pointerEvent.location = touches.first?.location(in: suitContainerView) ?? pointerEvent.location
//    pointerEventDelegate?.onPointerEvent(pointerEvent)
//    suitContainerView.layer.setNeedsDisplay()
//  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    kineticScrollingTimer?.stop()
    
    var pointerEvent = MouseEvent()
    pointerEvent.type = .click
    pointerEvent.location = touches.first?.location(in: suitContainerView) ?? pointerEvent.location
    _ = pointerEventDelegate?.onPointerEvent(pointerEvent)
    suitContainerView.layer.setNeedsDisplay()
  }
  
  @objc func tapHandler(_ sender: Any) {
    guard let gestureRecognizer = sender as? UITapGestureRecognizer else { return }

    var event = MouseEvent()
    event.type = .release
    event.location = gestureRecognizer.location(in: suitContainerView)
    _ = pointerEventDelegate?.onPointerEvent(event)
    suitContainerView.layer.setNeedsDisplay()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    suitContainerView.suitWindow?.rootView.frame = target.frame
    suitContainerView.suitWindow?.rootView.invalidateLayout()
    suitContainerView.layer.setNeedsDisplay()
  }
}

#endif
