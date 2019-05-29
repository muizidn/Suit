//
// Created by pmacro on 14/01/17.
//

#if os(Linux)
import Foundation
import X11
import Cairo

///
/// X11 window renderer.
///
public class X11Window {
  weak var window: Window!
  var surface: OpaquePointer!
  var display: OpaquePointer!
  var backBuffer: Drawable!
  var updateCount = 0

  let scale: CGFloat

  var graphicsContext: OpaquePointer!

  var isClosed: Bool = false

  /// The 'window' to pass to X11.
  var realX11Window: UInt!

  /// A GTK-style menu for the window.
  var gtkMenu: GtkStyleMenu?

  public init(window: Window, display: OpaquePointer!) {
    self.window = window
    self.display = display
    self.scale = DisplayUtils.getScaleFactor(forDisplay: display)
    surface = createSurface()!
  }

  ///
  /// Updates the window by redrawing its contents.
  ///
  func update(rect: CGRect) {
    if isClosed { return }
    guard rect.origin.x != CGFloat.infinity, rect.origin.y != CGFloat.infinity else { return }

    window.rootView.draw(dirtyRect: rect)

    XCopyArea(display,
              backBuffer,
              realX11Window,
              graphicsContext,
              Int32(rect.origin.x * scale),
              Int32(rect.origin.y * scale),
              UInt32(rect.width * scale),
              UInt32(rect.height * scale),
              Int32(rect.origin.x * scale),
              Int32(rect.origin.y * scale)
    )
    XFlush(display)
  }

  func createSurface() -> OpaquePointer? {
    let x = Int32(window.rootView.frame.origin.x * scale)
    let y = Int32(window.rootView.frame.origin.y * scale)
    let width = UInt32(window.rootView.frame.size.width * scale)
    let height = UInt32(window.rootView.frame.size.height * scale)

    let screen = XDefaultScreen(display)
    let parent = XDefaultRootWindow(display)

    realX11Window = XCreateSimpleWindow(display,
                                        parent,
                                        x,
                                        y,
                                        width,
                                        height,
                                        0,
                                        0,
                                        XWhitePixel(display, screen))

    XSelectInput(display,
                 realX11Window,
                 ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask |
                  ButtonReleaseMask | PointerMotionMask | StructureNotifyMask);

    backBuffer = XCreatePixmap(display, realX11Window,
                               UInt32(width), UInt32(height), UInt32(XDefaultDepth(display, screen)))

    graphicsContext = XCreateGC(display, realX11Window, 0, nil)

    let surface = cairo_xlib_surface_create(display, 
                                            backBuffer, 
                                            XDefaultVisual(display, screen), 
                                            Int32(width), 
                                            Int32(height))
    return surface
  }

  func show() {
    if isClosed { return }

    XMapWindow(display, realX11Window)
    XFlush(display)
  }

  func addChildWindowDecorations() {
    if isClosed { return }

    XSetWindowBorderWidth(display, realX11Window, 1) 
  }
}

extension X11Window: KeyEventDelegate {
  open func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    if let gtkMenu = gtkMenu {
      gtkMenu.onKeyboardShortcutPress(keyEvent)
    }
    return true // Meaningless here.
  }
}

extension X11Window: PlatformWindowDelegate {

  @usableFromInline
  var position: CGPoint {
    guard let tempDisplay = XOpenDisplay(nil), !isClosed else { return .zero }
    var child = UInt()
    var xwa = XWindowAttributes()
    var x = Int32()
    var y = Int32()
    XTranslateCoordinates(tempDisplay, 
                          realX11Window, 
                          XDefaultRootWindow(tempDisplay), 0, 0, &x, &y, &child)

    XGetWindowAttributes(tempDisplay, realX11Window, &xwa)
    XCloseDisplay(tempDisplay)

    return CGPoint(x: CGFloat(x - xwa.x) / scale, y: CGFloat(y - xwa.y) / scale)
  }

  @usableFromInline
  func move(to point: CGPoint) {
    if isClosed { return }

    var adjustedPoint = point

    // We don't use 'real' child windows since they can't exceed their parent's bounds
    // in X11, so we need to manually calculate the child's position relative to its parent.
    if let parentWindow = window.parentWindow {
      let parentPosition = parentWindow.x11Window.position
      adjustedPoint.x += parentPosition.x
      adjustedPoint.y += parentPosition.y
    }

    // TODO: this is an awful hack :-( 
    // These are observed values found through debugging.
    // Without these adjustments, window movements are 
    // off by these amounts.  I'm yet to figure out why this
    // is necessary, but better to have it functioning correctly
    // in the meantime.
    let xAdjustment: CGFloat = 10
    let yAdjustment: CGFloat = 8

    XMoveWindow(display,
                realX11Window,
                Int32((adjustedPoint.x + xAdjustment) * scale),
                Int32((adjustedPoint.y + yAdjustment) * scale))
  }

  @usableFromInline
  func hideWindowDecorations() {
    let property = XInternAtom(display, "_MOTIF_WM_HINTS", Int32(true))

    struct Hints {
      let flags: CUnsignedLong
      let functions: CUnsignedLong
      let decorations: CUnsignedLong
      let inputMode: CLong
      let status: CUnsignedLong
    }

    var hints = Hints(flags: 2, functions: 0, decorations: 2, inputMode: 0, status: 0)

    let count = MemoryLayout.size(ofValue: hints)
    withUnsafePointer(to: &hints) {
      $0.withMemoryRebound(to: UInt8.self, capacity: count) {
        XChangeProperty(display, realX11Window, property, property, 32, PropModeReplace, $0, 5)
        XFlush(display)
      }
    }
  }

  @usableFromInline
  func updateWindow() {
    update(rect: window.rootView.frame)
  }

  @usableFromInline
  func updateWindow(rect: CGRect) {
    update(rect: rect)
  }

  ///
  /// Maximizes the window.
  ///
  @usableFromInline
  func zoom() {
    var xwa = XWindowAttributes()
    let root = XDefaultRootWindow(display)
    XGetWindowAttributes(display, root, &xwa)
    XMoveResizeWindow(display, 
                      realX11Window, 
                      0, 
                      0, 
                      UInt32(xwa.width), 
                      UInt32(xwa.height))
  }

  ///
  /// Minimizes the window.
  ///
  @usableFromInline
  func minimize() {
    if isClosed { return }

    let screen = XDefaultScreen(display)
    XIconifyWindow(display, realX11Window, screen)
  }

  ///
  /// Closes the window.
  ///
  @usableFromInline
  func close() {
    if isClosed { return }
    isClosed = true
    XUnmapWindow(display, realX11Window)
    XDestroyWindow(display, realX11Window)  
  }

  ///
  /// Centers this window within its parent.
  ///
  @usableFromInline
  func center() {
    let parent: UInt!

    if let parentWindow = window.parentWindow {
      parent = parentWindow.x11Window.realX11Window
    } else {
      parent = XDefaultRootWindow(display)
    }

    var xwa = XWindowAttributes()
    XGetWindowAttributes(display, parent, &xwa)

    let viewWidth = window.rootView.frame.width
    let viewHeight = window.rootView.frame.height

    move(to: CGPoint(x: ((CGFloat(xwa.width) / scale) - viewWidth) / 2,
                     y: ((CGFloat(xwa.height) / scale) - viewHeight) / 2))
  }

  @usableFromInline
  func resize(to size: CGSize) {}

  @usableFromInline
  func applyMenu(_ menu: Menu) {
    gtkMenu = GtkStyleMenu(menu: menu)
    gtkMenu?.apply(to: window)
  }

  ///
  /// Brings this window to the front of a stack of peer windows.
  ///
  @usableFromInline
  func bringToFront() {
    XRaiseWindow(display, realX11Window)
  }

  ///
  /// By default, windows that aren't X11 child windows will display an icon in the task
  /// bar.  This function will supress that icon for this window.
  ///
  func hideTaskIcon() {
    setWMState(property: "_NET_WM_STATE_SKIP_TASKBAR")
  }

  ///
  /// Forces this window to be always on top of other windows.
  ///
  @usableFromInline
  func setAlwaysOnTop() {
    setWMState(property: "_NET_WM_STATE_ABOVE")
  }

  ///
  /// A helper method to set window manager state properties.
  ///
  /// - parameter property: the name of the property to enable.
  ///
  func setWMState(property: String) {
    let wmNetWmState = XInternAtom(display, "_NET_WM_STATE", 1)
    let wmProperty = XInternAtom(display, property, 1)

    var xclient = XClientMessageEvent()
    xclient.type = ClientMessage
    xclient.format = 32
    xclient.window = realX11Window
    xclient.message_type = wmNetWmState
    xclient.data.l.0 = 1 // 1 == _NET_WM_STATE_ADD
    xclient.data.l.1 = Int(wmProperty)
    xclient.data.l.2 = 0
    xclient.data.l.3 = 0
    xclient.data.l.4 = 0

    let capacity = MemoryLayout.size(ofValue: xclient)

    withUnsafePointer(to: &xclient) { (client: UnsafePointer<XClientMessageEvent>) -> Void in
      client.withMemoryRebound(to: XEvent.self, capacity: capacity) { (event: UnsafePointer<XEvent>) -> Void in
        XSendEvent(display, 
                   XDefaultRootWindow(display),
                   Int32(false),
                   SubstructureRedirectMask | SubstructureNotifyMask,
                   UnsafeMutablePointer(mutating: event))
        return
      }
    }
  }
}

#endif
