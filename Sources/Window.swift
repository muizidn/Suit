//
//  Window.swift
//  Suit
//
//  Created by pmacro  on 13/01/2017.
//
//

import Foundation

#if os(macOS)
import AppKit
#endif

@usableFromInline
protocol PlatformWindowDelegate {
  var position: CGPoint { get }
  func move(to: CGPoint)
  func updateWindow()
  func updateWindow(rect: CGRect)
  func zoom()
  func minimize()
  func close()
  func center()
  func resize(to size: CGSize)
  func applyMenu(_ menu: Menu)
  func bringToFront()
  func setAlwaysOnTop()
}
open class Window: KeyEventDelegate, PointerEventDelegate {

  #if os(macOS)
  public var macWindow: MacWindow!
  #endif

  #if os(Linux)
  var x11Window: X11Window!
  #endif

  @usableFromInline
  var platformWindowDelegate: PlatformWindowDelegate!
  public var id: Int
  static var idGenerator = 0

  weak public var parentWindow: Window?
  public var childWindows = [Window]()

  /// Holds the graphics used for drawing into this window.
  public var graphics: Graphics?

  weak public var focusedView: View?

  weak public var keyView: View? {
    didSet {
      if keyView != oldValue {
        oldValue?.didResignAsKeyView()
      }
    }
  }

  /// Does this window have a title bar?
  let hasTitleBar: Bool

  /// Configures whether or not the window should draw window buttons, i.e. minimize/zoom/close.
  var drawsSystemWindowButtons = true

  /// Set if the user has called center() on the window before it's been loaded.
  private var centerOnLoad = false

  
  /// The window title.
  public var title: String? {
    didSet {
      titleBar?.title = title
    }
  }
  
  /// The window's title bar.
  public var titleBar: TitleBar?
  
  /// The titleBar height.
  public var titleBarHeight: CGFloat {
    didSet {
      titleBar?.height = titleBarHeight~
    }
  }

  /// The current position of the window.
  public var position: CGPoint {
    return platformWindowDelegate.position
  }

  /// The window's menu.
  public var menu: Menu?
  {
    didSet {
      applyMenu()
    }
  }

  public let rootComponent: Component
  public var redrawManager: RedrawManager!
  public var rootView: View
  public var contentView: View

  public init(rootComponent: Component, frame: CGRect, hasTitleBar: Bool = true, title: String? = nil) {
    self.rootComponent = rootComponent
    self.title = title
    self.hasTitleBar = hasTitleBar

    #if os(macOS)
    titleBarHeight = 45
    #else
    titleBarHeight = 41
    #endif

    self.rootView = View()
    self.rootView.frame = frame
    contentView = View()

    Window.idGenerator += 1
    id = Window.idGenerator
    rootView.window = self

    redrawManager = RedrawManager(window: self)
    if hasTitleBar {
      titleBar = TitleBar(title: title)
      titleBar?.width = 100%
      titleBar?.height = titleBarHeight~
    }
  }

  public func makeMain() {
    Application.shared.mainWindow = self
  }
  
  func applyMenu() {
    if let menu = menu {
      platformWindowDelegate?.applyMenu(menu)
    }
  }

  public func reloadMenu() {
    applyMenu()
  }

  open func windowDidLaunch() {
    if centerOnLoad { center() }
    rootView.didAttachToWindow()
    rootComponent.loadView()

    if let titleBar = titleBar {
      titleBar.title = title
      rootView.add(subview: titleBar)
    }

    contentView = rootComponent.view

    rootView.add(subview: contentView)

    rootView.flexDirection = .column
    rootView.width = rootView.frame.size.width~
    rootView.height = rootView.frame.size.height~

    contentView.width = 100%

    if hasTitleBar {
      contentView.flex = 1
    } else {
      contentView.height = 100%
    }

    rootComponent.viewDidLoad()
    Appearance.refresh(window: self)
    rootView.invalidateLayout()
    platformWindowDelegate.updateWindow()
  }

  @discardableResult
  open func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    if let windowKeyEventDelegate = platformWindowDelegate as? KeyEventDelegate {
      _ = windowKeyEventDelegate.onKeyEvent(keyEvent)
    }
    
    if let keyView = keyView {
      if keyView.onKeyEvent(keyEvent) { return true }
    }

    return rootView.onKeyEvent(keyEvent)
  }

  open func close() {
    if let index = parentWindow?.childWindows.firstIndex(where: { $0.id == self.id}) {
      parentWindow?.childWindows.remove(at: index)
    }

    if let index = Application.shared.windows
      .firstIndex(where: { $0.id == id }) {
      Application.shared.windows.remove(at: index)
    }

    platformWindowDelegate.close()

    if Application.shared.windows.isEmpty {
      Application.shared.terminate()
    }
  }

  public func minimize() {
    platformWindowDelegate.minimize()
  }

  public func zoom() {
    platformWindowDelegate.zoom()
  }

  ///
  /// Moves this window to the specified point.  If this window has a parent window
  /// then `point` is relative to the top-left corner of the parent, otherwise
  /// `point` is relative to the top-left corner of the screen.
  ///
  /// - parameter point: the point to move the window to.
  ///
  public func move(to point: CGPoint) {
    platformWindowDelegate?.move(to: point)
  }

  ///
  /// centers this window within the current screen.
  ///
  public func center() {
    centerOnLoad = true
    platformWindowDelegate?.center()
  }

  ///
  /// Resizes this window.
  ///
  public func resize(to size: CGSize) {
    platformWindowDelegate?.resize(to: size)
  }

  public func bringToFront() {
    platformWindowDelegate?.bringToFront()
  }

  public func setAlwaysOnTop() {
    platformWindowDelegate?.setAlwaysOnTop()
  }

  ///
  /// Causes the window content to be redrawn.
  ///
  func updateWindow() {
    platformWindowDelegate?.updateWindow()
  }

  @inlinable
  func updateWindow(rect: CGRect) {
    platformWindowDelegate?.updateWindow(rect: rect)
  }

  @discardableResult
  open func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {

    // Close any child windows when the user clicks on the main window.  This behaviour
    // should be configurable in future.
    if !childWindows.isEmpty {
      if pointerEvent.type == .click {
        childWindows.forEach {
          $0.close()
        }
      }
    }

    if let focusedView = focusedView {
      // If this event concerns the focused view, pass the event to it, but if not,
      // then the view's focus is now invalid, so release it.
      if focusedView.hitTest(point: pointerEvent.location)
        || pointerEvent.type == .drag
        || pointerEvent.type == .release {
        if focusedView.onPointerEvent(pointerEvent) { return true}
      } else {
        releaseFocus(on: focusedView)
        sendSyntheticPointerExit(to: focusedView)
      }
    }
    return rootView.onPointerEvent(pointerEvent)
  }

  ///
  /// Locking focus on a view gives that view first opportunity on pointer events,
  /// and if it consumes the event, then no other view is passed the event.
  ///
  /// You can manually release this focus by calling `releaseFocus(on:)`, but note
  /// that the system will automatically release your focus when it receives pointer
  /// events that do not affect the focused view.
  ///
  func lockFocus(on view: View) {
    if let focusedView = focusedView, focusedView != view {
      releaseFocus(on: focusedView)
    }

    focusedView = view
  }

  ///
  /// Removes focus on the supplied view, if is already locked, otherwise does nothing.
  ///
  public func releaseFocus(on view: View) {
    if focusedView == view {
      focusedView = nil
      view.didReleaseFocus()
    }
  }

  private func sendSyntheticPointerExit(to view: View) {
    // Exit the previously focused view in case that hasn't already happened.
    view.onPointerEvent(PointerEvent(type: .exit,
                                     eventCount: 0,
                                     phase: .unknown,
                                     deltaX: 0,
                                     deltaY: 0,
                                     location: view.frame.origin,
                                     dragStartingPoint: nil))
  }
}
