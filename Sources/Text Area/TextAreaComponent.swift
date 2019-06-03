//
//  TextAreaComponent.swift
//  Suit
//
//  Created by pmacro  on 15/06/2018.
//

import Foundation

open class TextAreaComponent: CompositeComponent {
  
  open var textAreaView: TextAreaView?
  public let scrollView = ScrollView()
  let findComponent = TextAreaSearchComponent()

  open var textAreaViewType: TextAreaView.Type {
    return TextAreaView.self
  }

  open override func viewDidLoad() {
    super.viewDidLoad()
    view.flexDirection = .column
    
    textAreaView = textAreaViewType.init()
    textAreaView?.state.text = ""

    findComponent.textArea = textAreaView
    add(component: findComponent)
    
    view.add(subview: scrollView)
    
    scrollView.add(subview: textAreaView!)
    scrollView.width = 100%
    scrollView.flex = 1
  }
  
  open override func wasConfiguredAsChildComponent() {
    super.wasConfiguredAsChildComponent()
    
    textAreaView?.resizeToFitContent()
    view.window.rootView.invalidateLayout()
  }
  
  open override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    textAreaView?.updateAppearance(style: style)
  }
  
  public func scrollToBottom() {
    guard let textAreaView = textAreaView else { return }
    scrollView.scroll(to: CGPoint(x: 0, y: -textAreaView.frame.height))
  }
  
  public func toggleFindView() {
    findComponent.toggleVisibility()
  }
}
