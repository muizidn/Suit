//
//  View+Layout.swift
//  Suit
//
//  Created by pmacro on 10/02/2019.
//

import Foundation
import Yoga

public let LayoutUndefined = Float.nan

public enum LayoutPositionType: UInt32 {
  case relative
  case absolute
}

public enum LayoutDirection: UInt32 {
  case inherit
  case leftToRight
  case rightToLeft
}

public enum LayoutOverflow: UInt32 {
  case visible
  case hidden
  case scroll
}

public enum LayoutEdge: UInt32 {
  case left
  case top
  case right
  case bottom
  case start
  case end
  case horizontal
  case vertical
  case all
}

public enum LayoutUnit: UInt32 {
  case undefined
  case point
  case percent
  case auto
}

public enum LayoutAlignment: UInt32 {
  case auto
  case flexStart
  case center
  case flexEnd
  case stretch
  case baseline
  case spaceBetween
  case spaceAround
}

public struct LayoutValue: ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = Float

  public let unit: LayoutUnit
  public let value: Float

  public init(floatLiteral value: FloatLiteralType) {
    self.value = value
    self.unit = .point
  }

  public init(unit: LayoutUnit, value: Float) {
    self.unit = unit
    self.value = value
  }
}

public enum LayoutDisplay: UInt32 {
  case flex
  case none
}

public enum LayoutFlexDirection: UInt32 {
  case column
  case columnReverse
  case row
  case rowReverse
}

public enum LayoutJustifyContent: UInt32 {
  case flexStart
  case center
  case flexEnd
  case spaceBetween
  case spaceAround
  case spaceEvenly
}

public enum LayoutWrap: UInt32 {
  case noWrap
  case wrap
  case wrapReverse
}

postfix operator %

extension Float {
  public static postfix func %(value: Float) -> LayoutValue {
    return LayoutValue(unit: .percent, value: value)
  }
}

extension CGFloat {
  public static postfix func %(value: CGFloat) -> LayoutValue {
    return LayoutValue(unit: .percent, value: Float(value))
  }
}

extension Int {
  public static postfix func %(value: Int) -> LayoutValue {
    return LayoutValue(unit: .percent, value: Float(value))
  }
}

extension Int32 {
  public static postfix func %(value: Int32) -> LayoutValue {
    return LayoutValue(unit: .percent, value: Float(value))
  }
}

extension Double {
  public static postfix func %(value: Double) -> LayoutValue {
    return LayoutValue(unit: .percent, value: Float(value))
  }
}

postfix operator ~

extension Float {
  public static postfix func ~(value: Float) -> LayoutValue {
    return LayoutValue(unit: .point, value: value)
  }
}

extension CGFloat {
  public static postfix func ~(value: CGFloat) -> LayoutValue {
    return LayoutValue(unit: .point, value: Float(value))
  }
}

extension Int {
  public static postfix func ~(value: Int) -> LayoutValue {
    return LayoutValue(unit: .point, value: Float(value))
  }
}

extension Int32 {
  public static postfix func ~(value: Int32) -> LayoutValue {
    return LayoutValue(unit: .point, value: Float(value))
  }
}

extension Double {
  public static postfix func ~(value: Double) -> LayoutValue {
    return LayoutValue(unit: .point, value: Float(value))
  }
}

extension CGSize {
  public init(width: Float, height: Float) {
    self.init(width: CGFloat(width), height: CGFloat(height))
  }
}

extension View {

  /// The type of positioning to use when laying out this view: absolute, or relative.
  public var positionType: LayoutPositionType {
    get {
      let type = YGNodeStyleGetPositionType(yogaNode)
      return LayoutPositionType(rawValue: type.rawValue) ?? .relative
    }

    set {
      YGNodeStyleSetPositionType(yogaNode, YGPositionType(rawValue: newValue.rawValue))
    }
  }

  public func position(for edge: LayoutEdge) -> LayoutValue {
    let value = YGNodeStyleGetPosition(yogaNode, YGEdge(rawValue: edge.rawValue))
    return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                       value: value.value)
  }

  public func set(position: LayoutValue, for edge: LayoutEdge) {
    if position.unit == .percent {
      YGNodeStyleSetPositionPercent(yogaNode,
                                    YGEdge(rawValue: edge.rawValue),
                                    position.value)
    } else {
      YGNodeStyleSetPosition(yogaNode,
                             YGEdge(rawValue: edge.rawValue),
                             position.value)
    }
  }


  /// The direction in which this view's children should be laid out.
  public var direction: LayoutDirection {
    get {
      let value = YGNodeStyleGetDirection(yogaNode).rawValue
      return LayoutDirection(rawValue: value) ?? .inherit
    }

    set {
      YGNodeStyleSetDirection(yogaNode, YGDirection(rawValue: newValue.rawValue))
    }
  }

  public var display: LayoutDisplay {
    get {
      let value = YGNodeStyleGetDisplay(yogaNode).rawValue
      return LayoutDisplay(rawValue: value) ?? .flex
    }

    set {
      YGNodeStyleSetDisplay(yogaNode, YGDisplay(newValue.rawValue))
    }
  }

  public var flexDirection: LayoutFlexDirection {
    get {
      let value = YGNodeStyleGetFlexDirection(yogaNode).rawValue
      return LayoutFlexDirection(rawValue: value) ?? .row
    }

    set {
      YGNodeStyleSetFlexDirection(yogaNode, YGFlexDirection(rawValue: newValue.rawValue))
    }
  }

  /// The overflow behaviour.
  public var overflow: LayoutOverflow {
    get {
      let value = YGNodeStyleGetOverflow(yogaNode).rawValue
      return LayoutOverflow(rawValue: value) ?? .visible
    }

    set {
      YGNodeStyleSetOverflow(yogaNode, YGOverflow(rawValue: newValue.rawValue))
    }
  }

  public var width: LayoutValue {
    get {
      let value = YGNodeStyleGetWidth(yogaNode)
      return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                         value: value.value)
    }

    set {
      switch newValue.unit {
        case .auto:
          YGNodeStyleSetWidthAuto(yogaNode)
        case .percent:
          YGNodeStyleSetWidthPercent(yogaNode, newValue.value)
        case .point, .undefined:
          YGNodeStyleSetWidth(yogaNode, newValue.value)
      }
    }
  }

  public var maxWidth: LayoutValue {
    get {
      let value = YGNodeStyleGetMaxWidth(yogaNode)
      return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                         value: value.value)
    }

    set {
      switch newValue.unit {
        case .auto: break
        case .percent:
          YGNodeStyleSetMaxWidthPercent(yogaNode, newValue.value)
        case .point, .undefined:
          YGNodeStyleSetMaxWidth(yogaNode, newValue.value)
      }
    }
  }

  public var minWidth: LayoutValue {
    get {
      let value = YGNodeStyleGetMinWidth(yogaNode)
      return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                         value: value.value)
    }

    set {
      switch newValue.unit {
        case .auto: break
        case .percent:
          YGNodeStyleSetMinWidthPercent(yogaNode, newValue.value)
        case .point, .undefined:
          YGNodeStyleSetMinWidth(yogaNode, newValue.value)
      }
    }
  }


  public var height: LayoutValue {
    get {
      let value = YGNodeStyleGetHeight(yogaNode)
      return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                         value: value.value)
    }

    set {
      switch newValue.unit {
        case .auto:
          YGNodeStyleSetHeightAuto(yogaNode)
        case .percent:
          YGNodeStyleSetHeightPercent(yogaNode, newValue.value)
        case .point, .undefined:
          YGNodeStyleSetHeight(yogaNode, newValue.value)
      }
    }
  }

  public var maxHeight: LayoutValue {
    get {
      let value = YGNodeStyleGetMaxHeight(yogaNode)
      return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                         value: value.value)
    }

    set {
      switch newValue.unit {
        case .auto: break
        case .percent:
          YGNodeStyleSetMaxHeightPercent(yogaNode, newValue.value)
        case .point, .undefined:
          YGNodeStyleSetMaxHeight(yogaNode, newValue.value)
      }
    }
  }

  public var minHeight: LayoutValue {
    get {
      let value = YGNodeStyleGetMinHeight(yogaNode)
      return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                         value: value.value)
    }

    set {
      switch newValue.unit {
        case .auto: break
        case .percent:
          YGNodeStyleSetMaxHeightPercent(yogaNode, newValue.value)
        case .point, .undefined:
          YGNodeStyleSetMaxHeight(yogaNode, newValue.value)
      }
    }
  }

  public var aspectRatio: Float {
    get {
      return YGNodeStyleGetAspectRatio(yogaNode)
    }

    set {
      YGNodeStyleSetAspectRatio(yogaNode, newValue)
    }
  }

  public var wrap: LayoutWrap {
    get {
      let value = YGNodeStyleGetFlexWrap(yogaNode).rawValue
      return LayoutWrap(rawValue: value) ?? .wrap
    }

    set {
      YGNodeStyleSetFlexWrap(yogaNode, YGWrap(rawValue: newValue.rawValue))
    }
  }

  public var justifyContent: LayoutJustifyContent {
    get {
      let value = YGNodeStyleGetJustifyContent(yogaNode).rawValue
      return LayoutJustifyContent(rawValue: value) ?? .flexStart
    }

    set {
      YGNodeStyleSetJustifyContent(yogaNode, YGJustify(rawValue: newValue.rawValue))
    }
  }

  public var flexGrow: Float {
    get {
      return YGNodeStyleGetFlexGrow(yogaNode)
    }

    set {
      YGNodeStyleSetFlexGrow(yogaNode, newValue)
    }
  }

  public var flexShrink: Float {
    get {
      return YGNodeStyleGetFlexShrink(yogaNode)
    }

    set {
      YGNodeStyleSetFlexShrink(yogaNode, newValue)
    }
  }

  public var flex: Float {
    get {
      return YGNodeStyleGetFlex(yogaNode)
    }

    set {
      YGNodeStyleSetFlex(yogaNode, newValue)
    }
  }

  public var alignItems: LayoutAlignment {
    get {
      let value = YGNodeStyleGetAlignItems(yogaNode).rawValue
      return LayoutAlignment(rawValue: value) ?? .auto
    }

    set {
      YGNodeStyleSetAlignItems(yogaNode, YGAlign(rawValue: newValue.rawValue))
    }
  }

  public var alignContent: LayoutAlignment {
    get {
      let value = YGNodeStyleGetAlignContent(yogaNode).rawValue
      return LayoutAlignment(rawValue: value) ?? .auto
    }

    set {
      YGNodeStyleSetAlignContent(yogaNode, YGAlign(rawValue: newValue.rawValue))
    }
  }

  public var alignSelf: LayoutAlignment {
    get {
      let value = YGNodeStyleGetAlignSelf(yogaNode).rawValue
      return LayoutAlignment(rawValue: value) ?? .auto
    }

    set {
      YGNodeStyleSetAlignSelf(yogaNode, YGAlign(rawValue: newValue.rawValue))
    }
  }

  public func padding(for edge: LayoutEdge) -> LayoutValue {
    let value = YGNodeStyleGetPadding(yogaNode, YGEdge(rawValue: edge.rawValue))
    return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                       value: value.value)
  }

  public func set(padding: LayoutValue, for edge: LayoutEdge) {
    if padding.unit == .percent {
      YGNodeStyleSetPaddingPercent(yogaNode,
                                   YGEdge(rawValue: edge.rawValue),
                                   padding.value)
    } else {
      YGNodeStyleSetPadding(yogaNode,
                            YGEdge(rawValue: edge.rawValue),
                            padding.value)
    }
  }

  public func margin(for edge: LayoutEdge) -> LayoutValue {
    let value = YGNodeStyleGetMargin(yogaNode, YGEdge(rawValue: edge.rawValue))
    return LayoutValue(unit: LayoutUnit(rawValue: value.unit.rawValue) ?? .undefined,
                       value: value.value)
  }

  public func set(margin: LayoutValue, for edge: LayoutEdge) {
    if margin.unit == .percent {
      YGNodeStyleSetMarginPercent(yogaNode,
                                  YGEdge(rawValue: edge.rawValue),
                                  margin.value)
    } else {
      YGNodeStyleSetMargin(yogaNode,
                           YGEdge(rawValue: edge.rawValue),
                           margin.value)
    }
  }

  public var intrinsicSize: CGSize {
    let constrainedSize = CGSize(width: LayoutUndefined, height: LayoutUndefined)
    return calculateLayout(with: constrainedSize)
  }

  func calculateLayout(with size: CGSize) -> CGSize {
    assert(Thread.isMainThread, "Yoga calculation must be done on main.")

    YGNodeCalculateLayout(
      yogaNode,
      Float(size.width),
      Float(size.height),
      YGDirection(rawValue: direction.rawValue))

    return CGSize(width: width.value, height: height.value)
  }

  ///
  /// Apply the layout.
  ///
  func applyLayout() {
    //assert(Thread.isMainThread, "Framesetting should only be done on the main thread.")

    if superview == nil {
      YGNodeCalculateLayout(yogaNode,
                            LayoutUndefined,
                            LayoutUndefined,
                            YGDirection(rawValue: direction.rawValue))
    }

    let preserveOrigin = false

    let topLeft = CGPoint(x: CGFloat(YGNodeLayoutGetLeft(yogaNode)),
                          y: CGFloat(YGNodeLayoutGetTop(yogaNode)))

    let bottomRight = CGPoint(x: topLeft.x + CGFloat(YGNodeLayoutGetWidth(yogaNode)),
                              y: topLeft.y + CGFloat(YGNodeLayoutGetHeight(yogaNode)))

    let origin = preserveOrigin ? frame.origin : .zero

    frame = CGRect(origin: CGPoint(x: CGFloat(topLeft.x + origin.x),
                                   y: CGFloat(topLeft.y + origin.y)),
                   size: CGSize(width: bottomRight.x - topLeft.x,
                                height: bottomRight.y - topLeft.y))
  }
}
