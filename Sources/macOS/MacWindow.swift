//
//  MacWindow.swift
//  Suit
//
//  Created by pmacro  on 13/01/2017.
//
//

#if os(macOS)
import Foundation
import AppKit

public class MacWindow: NSWindow {
  weak var window: Window!
  var mouseEventDelegate: PointerEventDelegate?
  var keyEventDelegate: KeyEventDelegate?
  var isDragging = false
  var dragStartingPoint: CGPoint?
  var eventTimer: Timer?
  
  public override var hasTitleBar: Bool {
    return false
  }
  
  override init(contentRect: CGRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
    super.init(contentRect: contentRect,
               styleMask: style,
               backing: bufferingType,
               defer: flag)

    // We need the macOS title bar in order to be able to move the window between screens,
    // but we can make it be completely hidden so it doesn't interfere with Suit.
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    acceptsMouseMovedEvents = true
    delegate = self
  }
  
  public func windowDidChangeScreen(_ notification: Notification) {
    window.redrawManager.redraw(view: window.rootView)
  }
  
  public override func mouseMoved(with event: NSEvent) {
    guard let window = window else { return }
    var mouseEvent = PointerEvent()
    mouseEvent.type = .move
    mouseEvent.deltaX = event.deltaX
    mouseEvent.deltaY = event.deltaY

    mouseEvent.location = CGPoint(x: mouseLocationOutsideOfEventStream.x,
                                  y: window.rootView.frame.size.height - mouseLocationOutsideOfEventStream.y)
    _ = mouseEventDelegate?.onPointerEvent(mouseEvent)
  }
  
  public override func mouseDown(with event: NSEvent) {
    guard let window = window else { return }

    var mouseEvent = PointerEvent()
    mouseEvent.type = .click
    mouseEvent.eventCount = event.clickCount
    mouseEvent.location = CGPoint(x: event.locationInWindow.x,
                                  y: window.rootView.frame.size.height - event.locationInWindow.y)

    _ = mouseEventDelegate?.onPointerEvent(mouseEvent)
  }
  
  public override func mouseUp(with event: NSEvent) {
    guard let window = window else { return }

    var mouseEvent = PointerEvent()
    mouseEvent.type = .release
    mouseEvent.location = CGPoint(x: event.locationInWindow.x,
                                  y: window.rootView.frame.size.height - event.locationInWindow.y)
    _ = mouseEventDelegate?.onPointerEvent(mouseEvent)
    
    isDragging = false
  }
  
  public override func mouseDragged(with event: NSEvent) {
    guard let window = window else { return }

    let isDragStart = !isDragging
    isDragging = true
    
    var mouseEvent = PointerEvent()
    mouseEvent.type = .drag
    mouseEvent.deltaX = event.deltaX
    mouseEvent.deltaY = event.deltaY
    mouseEvent.location = CGPoint(x: mouseLocationOutsideOfEventStream.x,
                                  y: window.rootView.frame.size.height - mouseLocationOutsideOfEventStream.y)
    
    if isDragStart {
      dragStartingPoint = CGPoint(x: mouseLocationOutsideOfEventStream.x,
                                  y: window.rootView.frame.size.height - mouseLocationOutsideOfEventStream.y)
      mouseEvent.phase = .started
    }
    
    mouseEvent.dragStartingPoint = dragStartingPoint
    _ = mouseEventDelegate?.onPointerEvent(mouseEvent)
  }
  
  public override func mouseEntered(with event: NSEvent) {
    
  }
  
  public override func mouseExited(with event: NSEvent) {
  
  }
  
  public override func scrollWheel(with event: NSEvent) {
    super.scrollWheel(with: event)
    guard let window = window else { return }

    var mouseEvent = PointerEvent()
    mouseEvent.type = .scroll
    
    var phase: PointerEventPhase?
    
    switch event.momentumPhase {
      case .began:
        phase = .started
      case .ended:
        phase = .ended
      default:
        break
    }
    
    if phase == nil {
      switch event.phase {
        case .began:
        phase = .started
      case .ended:
        phase = .ended
      default:
        break
      }
    }
    
    mouseEvent.phase = phase ?? .unknown
    mouseEvent.deltaX = event.scrollingDeltaX
    mouseEvent.deltaY = event.scrollingDeltaY
    mouseEvent.location = CGPoint(x: mouseLocationOutsideOfEventStream.x,
                                  y: window.rootView.frame.size.height - mouseLocationOutsideOfEventStream.y)

    _ = mouseEventDelegate?.onPointerEvent(mouseEvent)
  }
  
  public override var canBecomeKey: Bool {
    return true
  }
  
  override public var acceptsFirstResponder: Bool {
    return true
  }
  
  public override func keyDown(with event: NSEvent) {
    // NB. Not calling super on purpose.  super calls NSBeep.
    _ = keyEventDelegate?.onKeyEvent(MacKeyEvent(event: event))
  }
  
  public override func keyUp(with event: NSEvent) {
    _ = keyEventDelegate?.onKeyEvent(MacKeyEvent(event: event))
  }
  
  public override func flagsChanged(with event: NSEvent) {
    _ = keyEventDelegate?.onKeyEvent(MacKeyEvent(event: event,
                                                 isFlagsChangedEvent: true))
  }
}

extension MacWindow: NSWindowDelegate {
  public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
    window.rootView.width = frameSize.width~
    window.rootView.height = frameSize.height~
    window.rootView.invalidateLayout()
    
    window.macWindow.contentView?.frame = window.rootView.frame
    window.redrawManager.redraw(view: window.rootView)
    return frameSize
  }
  
  public func windowDidExpose(_ notification: Notification) {
    window.redrawManager.redraw(view: window.rootView)
  }
  
  public func windowDidResize(_ notification: Notification) {
    updateWindow()
  }
  
  public func windowDidEndLiveResize(_ notification: Notification) {
    window.redrawManager.redraw(view: window.rootView)
  }
  
  public func windowDidBecomeMain(_ notification: Notification) {
    window.redrawManager.redraw(view: window.rootView)
  }
  
  public func windowDidBecomeKey(_ notification: Notification) {
    window.redrawManager.redraw(view: window.rootView)
  }
}
  
extension MacWindow: PlatformWindowDelegate {
  @usableFromInline
  func zoom() {
    zoom(nil)
  }
  
  @usableFromInline
  func minimize() {
    miniaturize(nil)
  }
  
  @usableFromInline
  var position: CGPoint {
    return frame.origin
  }
  
  @usableFromInline
  func move(to point: CGPoint) {
    var position = point

    // Move relative to parent window.
    if let parentWindow = window.parentWindow {
      position.x += parentWindow.position.x
      position.y = (parentWindow.position.y + parentWindow.rootView.frame.height)
        - position.y
    }
    
    // Necessary due to flipped coordinate system.
    position.y -= frame.height
    setFrameOrigin(position)
  }
  
  @usableFromInline
  func resize(to size: CGSize) {
    var newFrame = frame
    newFrame.size = size
    setFrame(newFrame, display: true, animate: false)
  }
  
  @usableFromInline
  func applyMenu(_ menu: Menu) {
    let mainMenu = NSMenu(title:"MainMenu")
    
    for item in menu.rootMenuItems {
      let menuItem = mainMenu.addItem(withTitle: item.title,
                                      action: nil,
                                      keyEquivalent: item.keyEquivalent ?? "")
      
      let submenu = NSMenu(title: item.title)
      
      if let subItems = item.subMenuItems {
        subItems.forEach {
          add($0, to: submenu)
        }
      }
      
      mainMenu.setSubmenu(submenu, for:menuItem)
    }
    
    self.menu = mainMenu
    NSApp.mainMenu = mainMenu
  }
  
  func add(_ menuItem: MenuItem, to menu: NSMenu) {
    let item = NSMenuItem(title: menuItem.title,
                              action: #selector(handleMenuItemAction),
                              keyEquivalent: menuItem.keyEquivalent ?? "")
    
    menuItem.keyEquivalentModifiers.forEach {
      item.keyEquivalentModifierMask.insert($0.asNSEventModifierFlag)
    }

    item.tag = menuItem.uniqueIdentifier
    menu.addItem(item)
  }
  
  @objc
  func handleMenuItemAction(_ sender: NSMenuItem?) {    
    if let identifier = sender?.tag {
      window.menu?.action(for: identifier)?()
    }
  }
  
  @usableFromInline
  func updateWindow(rect: NSRect) {
    var rectangle = rect
    // Flip the coordinate system for macOS.
    rectangle.origin.y = (window.rootView.frame.height - rect.height) - rect.origin.y
    contentView?.setNeedsDisplay(rectangle)
  }
  
  @usableFromInline
  func updateWindow() {
    contentView?.needsDisplay = true
  }
  
  @usableFromInline
  func bringToFront() {
    makeKeyAndOrderFront(self)
  }
  
  @usableFromInline
  func setAlwaysOnTop() {
    level = .floating
  }
}
#endif
