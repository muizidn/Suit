//
//  RedrawManager.swift
//  suit
//
//  Created by pmacro  on 23/05/2018.
//

import Foundation

///
/// Manages the redrawing of a view, determining the impact of a redrawn view on the views
/// around it and ensuring that, where necessary, other views are redrawn, too.
///
public class RedrawManager {
  
  @usableFromInline
  weak var window: Window?
  
  public init(window: Window) {
    self.window = window
  }
  
  var dirtyFrame: CGRect?
  
  ///
  /// Requests that `view` is redrawn as soon as possible.  Calling this may cause
  /// other views to be redrawn, too.
  ///
  @inlinable
  public func redraw(view: View, dirtyRect: CGRect? = nil) {
    view.isDirty = true
    
    guard let window = window else { return }

    let frame: CGRect
    var viewFrameInWindow: CGRect

    if let dirtyRect = dirtyRect {
      let point = view.coordinatesInWindowSpace(from: dirtyRect.origin)
      var frame = dirtyRect
      frame.origin = point
      viewFrameInWindow = frame
    } else {
      viewFrameInWindow = view.frameInWindow
    }
    
    if viewFrameInWindow.size.width.isNaN
      || viewFrameInWindow.size.height.isNaN
      || viewFrameInWindow.origin.x.isNaN
      || viewFrameInWindow.origin.y.isNaN { return }

    if let superview = view.superview {
      let superviewFrameInWindow = superview.frameInWindow

      if superviewFrameInWindow.size.width.isNaN
        || superviewFrameInWindow.size.height.isNaN
        || superviewFrameInWindow.origin.x.isNaN
        || superviewFrameInWindow.origin.y.isNaN { return }

      frame = superviewFrameInWindow.intersection(viewFrameInWindow)
      
      var parent = superview
      var this = view
      
      // Walk up the tree until we find an opaque view that is unaffected by the transparent child.
      while !this.isOpaque {
        parent.isDirty = true
        
        markDirty(views: parent.subviews.filter { $0 != view }, inRect: frame)
        
        if let parentView = this.superview {
          this = parent
          parent = parentView
        } else {
          break
        }
      }
    }
    else { 
      frame = viewFrameInWindow
    }
    
    markDirty(views: view.subviews, inRect: frame)
    window.updateWindow(rect: frame)
  }
  
  @inlinable
  func markDirty(views: [View], inRect rect: CGRect) {
    for view in views {
      if view.isInside(rect: rect) {
        view.isDirty = true
      }
      markDirty(views: view.subviews, inRect: rect)
    }
  }
}

