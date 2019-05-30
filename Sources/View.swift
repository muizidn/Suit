//
//  View.swift
//  Suit
//
//  Created by pmacro  on 13/01/2017.
//

import Foundation
import Yoga

var viewHashCounter = 0

public struct Gradient {
  public let colors: [Color]

  public init(colors: [Color]) {
    self.colors = colors
  }
}

public struct Background {

  public init() { }

  /// The view's background color.
  public var color = Color.clear

  public var borderSize: Double = 0
  public var borderColor = Color.black
  public var cornerRadius: Double = 0
  public var gradient: Gradient?
}

open class View: Hashable,
                 PointerEventDelegate,
                 AppearanceAdoption,
                 Scrollable,
                 Animatable {

  private var _frame: CGRect

  /// The rect of this view, in the window's co-ordinate space.
  public var frame: CGRect {
    set {
      _frame = newValue
      _bounds.size = newValue.size
    }

    get {
      return _frame
    }
  }

  @usableFromInline
  internal var frameInWindow: CGRect {
    let point = coordinatesInWindowSpace(from: _frame.origin)
    var frame = self.frame
    frame.origin = point

    // If this view is scrolled content, only the part visible in the scroll
    // is really part of the window.
    if let scrollView = embeddingScrollView {

      let scrollViewWindowFrame = scrollView.frameInWindow

      if scrollViewWindowFrame.size.width.isNaN || scrollViewWindowFrame.size.height.isNaN
        || scrollViewWindowFrame.origin.x.isNaN
        || scrollViewWindowFrame.origin.y.isNaN {
        return frame
      }

      if frame.size.width.isNaN 
        || frame.size.height.isNaN
        || frame.origin.x.isNaN
        || frame.origin.y.isNaN {
        return scrollViewWindowFrame
      }

      return frame.intersection(scrollViewWindowFrame)
    }

    return frame
  }

  private var _bounds: CGRect

  /// The rect of this view in its own coordinate space.
  public var bounds: CGRect {
    set {
      _bounds = newValue
    }
    get {
      return _bounds
    }
  }

  var visibleRect: CGRect {
    // Need to ensure we're not drawing outside of the superview's frame.
    return CGRect(x: totalInsets.left + frame.origin.x,
                  y: frame.origin.y + totalInsets.top,
                  width: min(bounds.size.width, frame.size.width - (insets.left + insets.right)),
                  height: min(bounds.size.height, frame.size.height) - (insets.top + insets.bottom))
  }

  /// This is the total insets of this view and its parents.  This value is used when drawing since we
  /// need to take into account all of the insets there.
  var totalInsets: EdgeInsets {
    return insets
  }

  /// The amount to inset this view.
  public var insets = EdgeInsets(left: 0, right: 0, top: 0, bottom: 0)

  /// This view's parent view, or nil if this view has no parent.
  public weak var superview: View?

  /// This view's child views.
  public var subviews: [View] = []

  /// The window to which this view belongs.
  public weak var window: Window!

  /// The graphics used to render this view.
  public var graphics: Graphics!

  internal var yogaNode: YGNodeRef!

  /// Specifies whether the yoga layout engine is enabled for this view.  This is true by default.
  /// If you set this to false, you are responsible for manually mangaging your view's frame.
  public var useLayoutEngine = true

  /// Should this view's contents be clipped at the 'bounds' rect?
  public var clipAtBounds = true

  /// By default views will only receive pointer events that fall within their bounds.
  /// You can set this property to true in order to receive all pointer events.
  public var wantsMouseEventsOutsideBounds = false

  /// True by default, this property indicates whether or not the view is interested in pointer event.
  /// If false, pointer events get passed to the parent view.
  public var acceptsMouseEvents = true

  /// Indicates whether or not this view supports touch input.  This properly is simply a shortcut
  /// to the same property on the shared Application object.
  public var supportsTouch: Bool {
    return Application.shared.supportsTouch
  }

  public var isDraggable = false
  public var isDraggingInView = false

  var hasMouseInside = false
  public var background = Background()

  /// Does this view need redrawn during the next draw operation?
  public var isDirty = true

  public var isHidden = false

  public var hasFocus: Bool {
    return window?.focusedView == self
  }

  public var hasKeyFocus: Bool {
    return window?.keyView == self
  }

  private var isManuallySetOpaque: Bool?
  
  private let viewId: Int

  public var isOpaque: Bool {
    set {
      isManuallySetOpaque = newValue
    }

    get {
      if let isManuallySetOpaque = isManuallySetOpaque {
        return isManuallySetOpaque
      }

      return background.color.alphaValue == 1 && background.cornerRadius == 0
    }
  }

  public required init() {
    _frame = .zero
    _bounds = .zero
    viewHashCounter += 1
    viewId = viewHashCounter

    let config = YGConfigNew()
    YGConfigSetExperimentalFeatureEnabled(config, YGExperimentalFeatureWebFlexBasis, true)    
    self.yogaNode = YGNodeNewWithConfig(config)
  }

  deinit {
    YGNodeFree(yogaNode)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(viewId)
  }
  
  public static func ==(lhs: View, rhs: View) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  ///
  /// Invoked just before this view attaches to a window.  Subclasses should call super.
  ///
  open func willAttachToWindow(){}

  ///
  /// Invoked just after this view attaches to a window.  Subclasses should call super.
  ///
  open func didAttachToWindow() {
    willAttachToWindow()
    subviews.forEach {
      $0.willAttachToWindow()
      $0.window = window
      $0.didAttachToWindow()
    }
  }

  ///
  /// Adds a view as a child of this view.
  ///
  public func add(subview: View) {
    subviews.append(subview)
    subview.superview = self
    subview.didAddToSuperview(self)
    subview.window = window

    if useLayoutEngine {
      if let existingOwner = YGNodeGetOwner(subview.yogaNode) {
        YGNodeRemoveChild(existingOwner, subview.yogaNode)
      }

      YGNodeSetMeasureFunc(yogaNode, nil)
      YGNodeInsertChild(yogaNode,
                        subview.yogaNode,
                        UInt32(subviews.count - 1))
    }

    if window != nil {
      subview.didAttachToWindow()
    }
  }

  ///
  /// Removes this view from its parent.
  ///
  public func removeFromSuperview() {
    if let superview = superview,
      let index = superview.subviews.firstIndex(where: { $0 == self }) {
      superview.subviews.remove(at: index)
      YGNodeRemoveChild(superview.yogaNode, yogaNode)
    }
  }

  ///
  /// Called whenever this view is added to a superview.  The default implementation does nothing.
  ///
  public func didAddToSuperview(_ superview: View) {}

  ///
  /// Forces this view to be redrawn.  Depending on the view's configuration, this may also
  /// cause n parent and child views to be redrawn.  Use of this method should generally be
  /// avoided outside of custom view implementations.
  ///
  public func forceRedraw() {
    window?.redrawManager.redraw(view: self)
  }

  // MARK: - Layout methods

  ///
  /// Invalidates this view's layout, i.e. the layout of all subviews contained within this view.
  ///
  public func invalidateLayout() {
    if useLayoutEngine {
      if subviews.isEmpty {
        YGNodeRemoveAllChildren(yogaNode)
        YGNodeSetMeasureFunc(yogaNode) { (node, width, widthMode, height, heightMode) -> YGSize in
          let constrainedWidth = (widthMode == YGMeasureModeUndefined)
            ?  100 : width
          let constrainedHeight = (heightMode == YGMeasureModeUndefined)
            ? 10 : height

          return YGSize(width: constrainedWidth, height: constrainedHeight)
        }
        YGNodeMarkDirty(yogaNode)
      }
      applyLayout()
    }

    subviews.forEach { $0.invalidateLayout() }
  }

  // MARK: - Drawing methods

  ///
  /// Ensures that the `graphics` property is set to a valid value, returning false if it could
  /// not set it to a valid value.
  ///
  internal func ensureGraphics() -> Bool {
    guard let window = window else { return false }

    // Lazily create the graphics object, or resuse an existing instance.
    if window.graphics == nil {
      PlatformGraphics.create(inWindow: window)
    }

    graphics = window.graphics
    graphics?.prepareForReuse()
    graphics?.point = coordinatesInWindowSpace(from: frame.origin)
    return graphics != nil
  }

  /// Converts the local coordinates found in frame.origin to the coordinate space within
  /// this view's window.
  public func coordinatesInWindowSpace(from: CGPoint) -> CGPoint {
    var local = from
    var parent = superview
    while let parentView = parent {
      local.x += parentView.frame.origin.x
      local.x += parentView.bounds.origin.x
      local.x += parentView.insets.left
      local.y += parentView.frame.origin.y
      local.y += parentView.bounds.origin.y
      local.y += parentView.insets.top
      parent = parentView.superview
    }

    return local
  }

  public func windowCoordinatesInViewSpace(from: CGPoint) -> CGPoint {
    var converted = from
    var parent: View? = self
    
    while parent != nil {      
      converted.x -= parent!.frame.origin.x
      converted.x -= parent!.bounds.origin.x
      converted.x -= parent!.insets.left
      converted.y -= parent!.frame.origin.y
      converted.y -= parent!.bounds.origin.y
      converted.y -= parent!.insets.top
      parent = parent!.superview
    }

    return converted
  }

  public func draw(dirtyRect: CGRect? = nil) {
    guard let window = window else { return }

    let screenFrame = window.rootView.frame
    let isOnScreen = !bounds.isEmpty && isInside(rect: screenFrame)

    if !isOnScreen {
      return
    }

    guard ensureGraphics() else { return }

    var rect: CGRect

    if let dirtyRect = dirtyRect {
      rect = dirtyRect
    } else {
      rect = bounds
      rect.origin.x = insets.left
      rect.size.width -= insets.right
      rect.origin.y = insets.top
      rect.size.height -= insets.bottom
    }

    if isDirty {
      draw(rect: rect)
    }

    subviews.forEach {
      if !$0.isHidden {
        $0.draw()
      }
    }

    graphics.flush()
    isDirty = false
  }

  public func draw(rect: CGRect) {
    graphics.set(color: background.color)

    if clipAtBounds {
      var bounds = self.bounds

      // superview?.superview because scrollview contents are wrapped inside another
      // view internally.
      if !(self is Scroller), let scrollView = superview?.superview as? ScrollView {
        bounds = CGRect(x: bounds.origin.x - scrollView.xOffsetTotal,
                        y: bounds.origin.y - scrollView.yOffsetTotal,
                        width: scrollView.frame.width,
                        height: scrollView.frame.height)
      }

      if background.cornerRadius > 0 {
        graphics.clip(roundedRectangle: bounds, cornerRadius: background.cornerRadius)
      } else {
        graphics.clip(rectangle: bounds)
      }
    }

    drawBackground(rect: rect)
  }

  public func drawBackground(rect: CGRect) {
    // If a gradient is defined, use it.  Otherwise fill the rectangle using the background color.
    if let gradient = background.gradient, gradient.colors.count > 1 {
      // TODO support multiple colors properly.  And more advanced gradient configuration.
      graphics.drawGradient(inRect: rect,
                            startColor: gradient.colors.first!,
                            stopColor: gradient.colors.last!)
    } else {
      graphics.set(color: background.color)
      if background.cornerRadius > 0 {
        graphics.draw(roundedRectangle: rect, cornerRadius: background.cornerRadius)
      } else {
        graphics.draw(rectangle: rect)
      }
      graphics.fill()
    }

    if background.borderSize > 0 {
      graphics.lineWidth = background.borderSize
      graphics.draw(roundedRectangle: rect, cornerRadius: background.cornerRadius)
      graphics.set(color: background.borderColor)
      graphics.stroke()
    }
  }

  @usableFromInline
  func isInside(rect: CGRect) -> Bool {
    let origin = coordinatesInWindowSpace(from: frame.origin)

    let result = (origin.x >= rect.origin.x || origin.x + bounds.size.width >= rect.origin.x)
      && origin.x <= (rect.origin.x + rect.size.width)
      && (origin.y >= rect.origin.y || origin.y + bounds.size.height >= rect.origin.y)
      && origin.y <= (rect.origin.y + rect.size.height)

    return result
  }

  // MARK: User interaction

  func hitTest(point: CGPoint) -> Bool {
    let rect = frameInWindow
    return point.x >= rect.origin.x
      && point.x <= (rect.origin.x + rect.size.width)
      && point.y >= rect.origin.y
      && point.y <= (rect.origin.y + rect.size.height)
  }

  // MARK: MouseEventDelegate

  ///
  /// Invoked by the system whenever a pointer event has occurred.
  ///
  /// - parameter pointerEvent: the pointer event.
  ///
  /// - returns: true if this view consumed the event, false if the event should be sent to
  ///  other qualifying views.
  ///
  @discardableResult
  func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    var wasConsumed = false

    guard acceptsMouseEvents else { return false }

    for subview in subviews.reversed() {
      let hitTest = subview.hitTest(point: pointerEvent.location) || subview.wantsMouseEventsOutsideBounds

      // Convert a "move" into an "exit" if the pointer was previously inside this view.
      if !hitTest {
        // We need to check for both .move and .exit since the parent view could have already converted
        // from a .move to a .exit.
        if pointerEvent.type == .move && subview.hasMouseInside {
          subview.hasMouseInside = false
          var event = pointerEvent
          event.type = .exit
          wasConsumed = wasConsumed || subview.onPointerEvent(event)
        }
        else if pointerEvent.type == .release && subview.hasMouseInside {
          subview.hasMouseInside = false
          wasConsumed = wasConsumed || subview.onPointerEvent(pointerEvent)
        }
      }

      // We need to count a drag as a hit if the drag started within the view, otherwise
      // the dragging of the window will suddenly stop once the pointer leaves the view's bounds
      if pointerEvent.type == .drag && subview.hitTest(point: pointerEvent.dragStartingPoint!) {
        subview.isDraggingInView = true
        wasConsumed = wasConsumed || subview.onPointerEvent(pointerEvent)
      }

      if hitTest {
        // Convert a "move" into an "enter" if the pointer wasn't previously inside this view.
        if !subview.hasMouseInside && pointerEvent.type == .move {
          subview.hasMouseInside = true
          var event = pointerEvent
          event.type = .enter
          subview.onPointerEvent(event)
        } else if pointerEvent.type == .release {
          subview.isDraggingInView = false
          wasConsumed = wasConsumed || subview.onPointerEvent(pointerEvent)
        } else {
          wasConsumed = wasConsumed || subview.onPointerEvent(pointerEvent)
        }
      }

      if wasConsumed { break }
    }
    return wasConsumed
  }

  ///
  /// Makes this view the view that first responds to key events.
  ///
  public func makeKeyView() {
    window?.keyView = self
  }

  ///
  /// Stops this view being the first reciever of key events.
  ///
  public func resignAsKeyView() {
    if window?.keyView == self {
      window.keyView = nil
    }
  }

  ///
  /// Called whenever the view loses focus.  The default implementation does nothing.
  ///
  public func didReleaseFocus() {}

  ///
  /// Called whenever the view stops being the key view.  The default implementation does nothing.
  ///
  public func didResignAsKeyView() {}

  @discardableResult
  func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    for subview in subviews.reversed() {
      if subview.onKeyEvent(keyEvent) {
        return true
      }
    }

    return false
  }

  func didScroll(to rect: CGRect) {}

  open func updateAppearance(style: AppearanceStyle) {}
  
  ///
  /// Generates the list of properties for animation, appending to the passed-in `properties` value.
  ///
  public func generateAnimatableProperties<T>(in properties: AnimatableProperties<T>) {
    if let properties = properties as? AnimatableProperties<View> {
      properties.add(\.background.borderSize)
      properties.add(\.width)
      properties.add(\.height)
    }    
  }
  
  public func cancelActiveAnimations() {
    Animator.cancelAnimations(for: self)
  }
}

extension Array where Element == View {

  ///
  /// Marks all views in the array, and the children of those views, as dirty.
  ///
  func setDirty() {
    for view in self {
      view.isDirty = true
      view.subviews.setDirty()
    }
  }
}
