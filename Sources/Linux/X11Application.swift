//
//  X11Application.swift
//  Suit
//
//  Created by pmacro on 27/02/2019.
//

#if os(Linux)

import Foundation
import Glibc
import X11
import Cairo

/// Replacement for FD_ZERO macro

func fdZero(set: inout fd_set) {
  set.__fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

/// Replacement for FD_SET macro

func fdSet(fd: Int32, set: inout fd_set) {
  let intOffset = Int(fd / 16)
  let bitOffset: Int = Int(fd % 16)
  let mask: Int = 1 << bitOffset
  switch intOffset {
    case 0: set.__fds_bits.0 = set.__fds_bits.0 | mask
    case 1: set.__fds_bits.1 = set.__fds_bits.1 | mask
    case 2: set.__fds_bits.2 = set.__fds_bits.2 | mask
    case 3: set.__fds_bits.3 = set.__fds_bits.3 | mask
    case 4: set.__fds_bits.4 = set.__fds_bits.4 | mask
    case 5: set.__fds_bits.5 = set.__fds_bits.5 | mask
    case 6: set.__fds_bits.6 = set.__fds_bits.6 | mask
    case 7: set.__fds_bits.7 = set.__fds_bits.7 | mask
    case 8: set.__fds_bits.8 = set.__fds_bits.8 | mask
    case 9: set.__fds_bits.9 = set.__fds_bits.9 | mask
    case 10: set.__fds_bits.10 = set.__fds_bits.10 | mask
    case 11: set.__fds_bits.11 = set.__fds_bits.11 | mask
    case 12: set.__fds_bits.12 = set.__fds_bits.12 | mask
    case 13: set.__fds_bits.13 = set.__fds_bits.13 | mask
    case 14: set.__fds_bits.14 = set.__fds_bits.14 | mask
    case 15: set.__fds_bits.15 = set.__fds_bits.15 | mask
    default: break
  }
}

public class X11Application: Application {

  var lastButtonPressTime: UInt = 0

  var clickCount = 1
  var dragStartingPoint: CGPoint?
  var isMouseDown = false
  let eventQueue = DispatchQueue(label: "eventQueue",
                                 qos: .userInteractive,
                                 attributes: .concurrent,
                                 autoreleaseFrequency: .workItem,
                                 target: nil)

  // Previous pointer move positions, used for calculating deltas.
  var lastX: Int32?
  var lastY: Int32?

  var pointerEventThrottler = EventThrottler(schedule: 0.05)
  var eventChecker = RepeatingTimer(timeInterval: 1 / 60)

  let display = XOpenDisplay(nil)!

  public override func launch() {
    Cursor.shared = X11Cursor()
    add(window: mainWindow)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.run()
    }
    dispatchMain()
  }

  public override func terminate() {
    XCloseDisplay(display)
  }

  public override func add(window: Window, asChildOf parentWindow: Window? = nil) {
    let frame = window.rootView.frame
    window.parentWindow = parentWindow

    let x11Window = X11Window(window: window, display: display)
    window.x11Window = x11Window
    window.platformWindowDelegate = x11Window
    x11Window.hideWindowDecorations()

    if parentWindow == nil, let iconPath = iconPath {
      x11Window.setIcon(path: iconPath)
    }
    
    x11Window.show()

    if parentWindow != nil {
      window.move(to: frame.origin)
      x11Window.addChildWindowDecorations()
      x11Window.hideTaskIcon()
    }

    super.add(window: window, asChildOf: parentWindow)

    window.rootView.invalidateLayout()
    window.rootView.forceRedraw()
    x11Window.update(rect: window.rootView.bounds)
  }

  public func run() {
    eventQueue.async {
      self.checkEvent(surface: self.mainWindow.x11Window.surface)
    }
  }

  func checkEvent(surface: OpaquePointer) {
    var event: XEvent = XEvent()

    while true {

      let fd = XConnectionNumber(display)
      var active_fd_set = fd_set()
      fdSet(fd: fd, set: &active_fd_set)

      let count = select(FD_SETSIZE, &active_fd_set, nil, nil, nil)

      guard count > 0 else {
        continue
      }

      // We can't make any X calls outside the main loop.  But having the 
      // blocking while-loop be outside main prevents main from being completely blocked
      // by event checking.  
      DispatchQueue.main.sync {
        while XPending(self.display) != 0 {
          XNextEvent(self.display, &event)
          self.handle(event: event)
        }
      }
    }
  }

  func handle(event: XEvent) {

    switch event.type {
      case Expose:
        guard let window = findWindow(forNativePointer: event.xexpose.window) else { return }
        window.rootView.invalidateLayout()
        window.rootView.forceRedraw()
        window.x11Window.update(rect: window.rootView.frame)
      case ConfigureNotify:
        guard let window = findWindow(forNativePointer: event.xconfigure.window) else { return }
        let scale = window.x11Window.scale
        let width = CGFloat(event.xconfigure.width) / scale
        let height = CGFloat(event.xconfigure.height) / scale
        
        window.rootView.width = width~
        window.rootView.height = height~
        let x11Window = window.x11Window!

        let screen = XDefaultScreen(x11Window.display)
        x11Window.backBuffer = XCreatePixmap(x11Window.display,
                                             x11Window.realX11Window,
                                             UInt32(event.xconfigure.width),
                                             UInt32(event.xconfigure.height),
                                             UInt32(XDefaultDepth(x11Window.display, screen)))

        x11Window.graphicsContext = XCreateGC (x11Window.display, 
                                               x11Window.realX11Window, 0, nil)

        x11Window.surface = cairo_xlib_surface_create(x11Window.display,
                                                      x11Window.backBuffer,
                                                      XDefaultVisual(x11Window.display, screen),
                                                      event.xconfigure.width,
                                                      event.xconfigure.height)

        window.rootView.invalidateLayout()
        window.rootView.forceRedraw()
        x11Window.update(rect: window.rootView.frame)

      case ButtonPress:
        guard let window = findWindow(forNativePointer: event.xbutton.window) else { return }
        let scale = window.x11Window.scale

        var pointerEvent = PointerEvent()
        pointerEvent.location = CGPoint(x: CGFloat(event.xbutton.x) / scale,
                                        y: CGFloat(event.xbutton.y) / scale)

        // TODO this is temporary, rudimentary, scrolling support.
        if event.xbutton.button == Button5 {
          pointerEvent.type = .scroll
          pointerEvent.deltaY = -100
        }
        else if event.xbutton.button == Button4 {
          pointerEvent.type = .scroll
          pointerEvent.deltaY = 100
        }
        else if event.xbutton.button == Button3 {
          pointerEvent.type = .rightClick
        }
        else {
          if event.xbutton.time - lastButtonPressTime < 400 {
            clickCount += 1
          } else {
            clickCount = 1
          }

          lastButtonPressTime = event.xbutton.time

          pointerEvent.type = .click
          pointerEvent.eventCount = clickCount

          self.isMouseDown = true
        }
        window.onPointerEvent(pointerEvent)
      case ButtonRelease:
        guard let window = findWindow(forNativePointer: event.xbutton.window) else { return }
        let scale = window.x11Window.scale

        var pointerEvent = PointerEvent()
        pointerEvent.type = .release
        pointerEvent.location = CGPoint(x: CGFloat(event.xbutton.x) / scale,
                                        y: CGFloat(event.xbutton.y) / scale)
        lastX = nil
        lastX = nil
        dragStartingPoint = nil
        isMouseDown = false
        window.onPointerEvent(pointerEvent)
      case MotionNotify:
        guard let window = findWindow(forNativePointer: event.xmotion.window) else { return }
        let scale = window.x11Window.scale

        pointerEventThrottler.add {
        var pointerEvent = PointerEvent()
        pointerEvent.type = self.isMouseDown ? .drag : .move
        pointerEvent.location = CGPoint(x: CGFloat(event.xmotion.x) / scale,
                                        y: CGFloat(event.xmotion.y) / scale)

        if let lastX = self.lastX, let lastY = self.lastY {
          pointerEvent.deltaX = CGFloat(event.xmotion.x_root - lastX) / scale
          pointerEvent.deltaY = CGFloat(lastY - event.xmotion.y_root) / scale
        }

        self.lastX = event.xmotion.x_root
        self.lastY = event.xmotion.y_root

        if pointerEvent.type == .drag, self.dragStartingPoint == nil {
          self.dragStartingPoint = pointerEvent.location
        }

        pointerEvent.dragStartingPoint = self.dragStartingPoint
        window.onPointerEvent(pointerEvent)
      }
      case ButtonPress:
        switch Int32(event.xbutton.button) {
          case Button4:
            print("Scrolled up")
          case Button5:
            print("Scrolled down")
          default:
            break
      }
      case KeyPress:
        guard let window = findWindow(forNativePointer: event.xkey.window) else { return }
        let keyEvent = LinuxKeyEvent(event: event.xkey, type: .down)
        window.onKeyEvent(keyEvent)
      case KeyRelease:
        guard let window = findWindow(forNativePointer: event.xkey.window) else { return }
        let keyEvent = LinuxKeyEvent(event: event.xkey, type: .up)
        window.onKeyEvent(keyEvent)
      default:
        break
        print("Dropping unhandled XEvent.type \(event.type)")
    }
  }

  func findWindow(forNativePointer native: UInt) -> Window? {
    if mainWindow.x11Window.realX11Window == native {
      return mainWindow.x11Window.isClosed ? nil : mainWindow
    }

    for child in windows {
      if child.x11Window.realX11Window == native {
        return child.x11Window.isClosed  ? nil : child
      }
    }

    return nil
  }
}

#endif
