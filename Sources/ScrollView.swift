//
//  ScrollView.swift
//  Suit
//
//  Created by pmacro on 22/01/2017.
//
//

import Foundation

public enum VerticalScrollPosition {
  case top
  case middle
  case bottom
}

public enum HorizontalScrollPosition {
  case left
  case center
  case right
}

protocol Scrollable {
  func didScroll(to rect: CGRect)
}

///
/// A view that contains a single content view and provides scrolling around any part
/// of that content view that is bigger than the scroll view itself.
///
public class ScrollView: View {
  
  let scrollerWidth: CGFloat = 15

  var xOffset: CGFloat = 0
  var yOffset: CGFloat = 0
  
  var xOffsetTotal: CGFloat = 0
  var yOffsetTotal: CGFloat = 0
  
  var startX: CGFloat = 0
  var startY: CGFloat = 0

  var verticalScroller: Scroller?
  var horizontalScroller: Scroller?
  
  var verticalScrollerAnimation: Animation?
  var contentBoundsChangeAnimation: Animation?
  var horizontalScrollerAnimation: Animation?
  
  var hideScrollersTimer: RepeatingTimer?
  
  var contentWrapper: View = View()
  weak var scrolledView: View?
  
  /// For vertical scrollers, this sets the minimum height of the scroller.  For horizontal scrollers
  /// it sets the minimum width.  Setting this value to a size large than the scroll view is invalid.
  public var minScrollerSize: CGFloat = 20
  
  public var showVerticalScrollbar = true {
    didSet {
      verticalScroller?.isHidden = !showVerticalScrollbar
    }
  }
  
  public var showHorizontalScrollbar = true {
    didSet {
      horizontalScroller?.isHidden = !showHorizontalScrollbar
    }
  }

  public required init() {
    super.init()
  }
  
  public override func add(subview: View) {
    if subviews.count == 0 {
      scrolledView = subview
      startX = bounds.origin.x
      startY = bounds.origin.y
      
      verticalScroller = Scroller()
      verticalScroller?.scrollView = self
      verticalScroller?.isHidden = !showVerticalScrollbar
      
      verticalScroller?.width = scrollerWidth~
      verticalScroller?.height = 100%
      
      horizontalScroller = Scroller()
      horizontalScroller?.scrollView = self
      horizontalScroller?.isHidden = !showHorizontalScrollbar
      
      horizontalScroller?.width = 100%
      horizontalScroller?.height = scrollerWidth~
      horizontalScroller?.isHorizontal = true
      
      contentWrapper.frame = bounds
      contentWrapper.add(subview: subview)
      
      subview.isOpaque = false
      contentWrapper.isOpaque = false
      
      super.add(subview: contentWrapper)
      super.add(subview: verticalScroller!)
      super.add(subview: horizontalScroller!)
    } else {
      fatalError("A ScrollView can only contain one subview")
    }
  }
  
  public override func didAttachToWindow() {
    super.didAttachToWindow()
    hideScrollersTimer = RepeatingTimer(timeInterval: 2)
    hideScrollersTimer?.eventHandler = { [weak self] in
      DispatchQueue.main.async {
        if self?.verticalScroller?.state != .focused && self?.horizontalScroller?.state != .focused {
          self?.verticalScroller?.hide()
          self?.horizontalScroller?.hide()
          self?.hideScrollersTimer?.stop()
        }
      }
    }
    hideScrollersTimer?.start()
  }

  public override func invalidateLayout() {
    super.invalidateLayout()
    
    if let view = scrolledView {
      // Reset everything to its original state.  This is something to be
      // careful of because if this isn't right, hit targets will be off.
      contentWrapper.bounds = CGRect(x: contentWrapper.bounds.origin.x,
                                     y: contentWrapper.bounds.origin.y,
                                     width: view.frame.size.width,
                                     height: view.frame.size.height)
    }
    
    if let verticalScroller = verticalScroller {
      performVerticalScrollerUpdates(scroller: verticalScroller)
    }

    if let horizontalScroller = horizontalScroller {
      performHorizontalScrollerUpdates(scroller: horizontalScroller)
    }
  }
  
  public func contentsDidChange() {
    xOffset = 0
    yOffset = 0
    xOffsetTotal = 0
    yOffsetTotal = 0
        
    window?.rootView.invalidateLayout()
  }
  
  func performScrollLayoutUpdates(view: View) {
    func adjustBounds() {
      contentWrapper.bounds.origin.y = yOffsetTotal
      contentWrapper.bounds.origin.x = xOffsetTotal
    }
    
    adjustBounds()
    
    let scrolledRect = CGRect(origin: contentWrapper.bounds.origin, size: frame.size)
    scrolledView?.didScroll(to: scrolledRect)
  }

  func performVerticalScrollerUpdates(scroller: Scroller) {
    let scrollFraction = min(1, frame.height / scrolledView!.frame.height)
    scroller.isHidden = !showVerticalScrollbar || scrollFraction == 1
    
    var height = scrollFraction * frame.height
    var scrollerPositionAdjustment: CGFloat = 0
    
    // The fraction the scroll is towards being complete, i.e. 0.0 is
    // unscrolled, 1.0 is fully scrolled.
    let scrollCompletionFraction = (scrollFraction * -yOffsetTotal) / frame.height
    
    if height < minScrollerSize {
      scrollerPositionAdjustment = (minScrollerSize - height) * scrollCompletionFraction
      height = minScrollerSize
    }
    
    scroller.height = height~
    scroller.frame.size = CGSize(width: scrollerWidth, height: height)
    scroller.frame.origin.y = (scrollFraction * -yOffsetTotal) - scrollerPositionAdjustment
    scroller.frame.origin.x = frame.width - 15
  }
  
  func performHorizontalScrollerUpdates(scroller: Scroller) {
    let scrollFraction = min(1, frame.width / scrolledView!.frame.width)
    scroller.isHidden = !showHorizontalScrollbar || scrollFraction == 1

    var width = scrollFraction * frame.width
    
    var scrollerPositionAdjustment: CGFloat = 0
    
    // The fraction the scroll is towards being complete, i.e. 0.0 is
    // unscrolled, 1.0 is fully scrolled.
    let scrollCompletionFraction = (scrollFraction * -xOffsetTotal) / frame.width
    
    if width < minScrollerSize {
      scrollerPositionAdjustment = (minScrollerSize - width) * scrollCompletionFraction
      width = minScrollerSize
    }

    scroller.width = width~
    scroller.frame.size = CGSize(width: width, height: scrollerWidth)
    scroller.frame.origin.x = (scrollFraction * -xOffsetTotal) - scrollerPositionAdjustment
    scroller.frame.origin.y = frame.height - 15
  }

  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    if super.onPointerEvent(pointerEvent) {
      return true
    }
    
    if pointerEvent.type == .scroll {
      scroll(to: CGPoint(x: xOffsetTotal + pointerEvent.deltaX,
                         y: yOffsetTotal + pointerEvent.deltaY))
    }
    return false
  }
  
  ///
  /// Scrolls to the top of the scroll view's contents.
  ///
  public func scrollToTop() {
    scroll(to: .zero)
  }
  
  ///
  /// Scrolls the scroll view to the specified point.
  ///
  public func scroll(to point: CGPoint) {
    if let verticalScroller = verticalScroller,
      verticalScroller.state == .inactive {
      verticalScroller.show()
      hideScrollersTimer?.resume()
    }
    
    if let horizontalScroller = horizontalScroller,
      horizontalScroller.state == .inactive {
      horizontalScroller.show()
      hideScrollersTimer?.resume()
    }
    
    hideScrollersTimer?.suspend(for: 2)
    
    guard let scrolledView = scrolledView else { return }

    yOffsetTotal = point.y
    yOffsetTotal = max(yOffsetTotal, frame.height - scrolledView.frame.height)
    yOffsetTotal = min(0, yOffsetTotal)
    
    xOffsetTotal = point.x
    xOffsetTotal = max(xOffsetTotal, frame.width - scrolledView.frame.width)
    xOffsetTotal = min(0, xOffsetTotal)
    
    performScrollLayoutUpdates(view: scrolledView)
    
    if let horizontalScroller = horizontalScroller {
      performHorizontalScrollerUpdates(scroller: horizontalScroller)
    }
    
    if let verticalScroller = verticalScroller {
      performVerticalScrollerUpdates(scroller: verticalScroller)
    }
    
    forceRedraw()
  }
  
  public override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    background.color = scrolledView?.background.color ?? .backgroundColor
  }
}

///
/// A scroller view.
///
class Scroller: View {
  
  /// The width of the scroller whenever it's not under the pointer.
  var unfocusedSize: CGFloat = 11
  
  /// The width of the scroller whenever it's under the pointer.
  var focusedSize: CGFloat = 15
  
  /// The current size of the scroller.
  var currentSize: CGFloat = 11
  
  var radius: Double = 8
  
  var hasBeenGrabbed = false
  
  weak var scrollView: ScrollView?
  
  /// Declares whether this is a horizontal or vertical scroller.  The default value is false.
  var isHorizontal = false
  
  var focusedBackgroundColor: Color = .black
  var inactiveBackgroundColor: Color = .clear
  
  var currentBackgroundColor: Color?
  
  var activeScollerAnimation: Animation?
  
  enum State {
    case focused
    case unfocused
    case inactive
  }
  
  var state = State.inactive
  
  override func generateAnimatableProperties<T>(in properties: AnimatableProperties<T>) where T: Scroller {
    super.generateAnimatableProperties(in: properties)
    properties.add(\.radius)
    properties.add(\.currentSize)
  }
  
  func hide() {
    state = .inactive
    isHidden = true
    forceRedraw()
  }

  func show() {
    if state != .unfocused {
      state = .unfocused
      isHidden = false
      forceRedraw()
    }
  }
  
  ///
  /// Override the background drawing in order to draw the scroller as a rounded
  /// rectangle.
  ///
  override func drawBackground(rect: CGRect) {
    guard scrollView != nil, !isHidden else { return }
    var rectangle = rect
    
    if isHorizontal {
      rectangle.size.height = currentSize
      rectangle.origin.y = frame.height - currentSize
    } else {
      rectangle.size.width = currentSize
      rectangle.origin.x = frame.width - currentSize
    }

    rectangle = rectangle.insetBy(dx: 2, dy: 2)

    graphics.set(color: currentBackgroundColor ?? background.color)
    graphics.draw(roundedRectangle: rectangle, cornerRadius: radius)
    graphics.fill()
  }
  
  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    
    background.color = .scrollBarColor
    focusedBackgroundColor = .scrollBarColor
    currentBackgroundColor = .scrollBarColor
  }
  
  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    var wasConsumed = super.onPointerEvent(pointerEvent)

    if wasConsumed || isHidden {
      return wasConsumed
    }
    
    if pointerEvent.type == .release {
      hasBeenGrabbed = false
      window.releaseFocus(on: self)
      wasConsumed = true
    }
    else if pointerEvent.type == .click {
      hasBeenGrabbed = true
      wasConsumed = true
      window.lockFocus(on: self)
    }
    else if pointerEvent.type == .drag {
      wasConsumed = true
      var event = pointerEvent
      event.type = .scroll
      
      let location = windowCoordinatesInViewSpace(from: event.location)
      
      if isHorizontal {
        // The scroll should feel like it's centered on the point in the scroller that
        // is grabbed, so we need to find the position the scroller where the pointer
        // is and include that in any events.
        let positionOnXScroller = location.x - frame.width
        // The X delta is the difference between the position of the scroller,
        // the position of the pointer, adding the position on the scroller.
        let x = frame.origin.x - (location.x + positionOnXScroller)
        event.deltaX = x
        event.deltaY = 0
      } else {
        let positionOnYScroller = location.y - frame.height
        let y = frame.origin.y - (location.y + positionOnYScroller)
        
        event.deltaY = y
        event.deltaX = 0
      }
      _ = scrollView?.onPointerEvent(event)
      window.redrawManager.redraw(view: self)
    }
    
    if pointerEvent.type == .enter && state != .focused {
      window.lockFocus(on: self)
      state = .focused
      activeScollerAnimation?.cancel()
      animate(duration: 0.2, easing: .quadraticEaseIn, changes: {
        self.currentBackgroundColor = focusedBackgroundColor
        self.currentSize = focusedSize
        self.radius = 12
      })
      Cursor.shared.push(type: .arrow)
    }
    else if pointerEvent.type == .exit && state != .unfocused {
      state = .unfocused
      activeScollerAnimation?.cancel()
      animate(duration: 0.2, easing: .quadraticEaseIn, changes: {
        self.currentBackgroundColor = background.color
        self.currentSize = unfocusedSize
        self.radius = 8
      })
      Cursor.shared.pop()
    }
    
    return wasConsumed
  }
}

extension View {
  public var embeddingScrollView: ScrollView? {
    var parent: View? = superview
    
    while parent != nil {
      if let parent = parent as? ScrollView {
        return parent
      }
      parent = parent?.superview
    }
    
    return nil
  }
}
