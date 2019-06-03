//
//  ContextMenuItemCell.swift
//  Suit
//
//  Created by pmacro on 03/06/2019.
//

import Foundation

class ContextMenuItemCell: ListViewCell {
  let titleLabel = Label()
  let secondaryLabel = Label()
  
  override func didAttachToWindow() {
    super.didAttachToWindow()
    flexDirection = .row
    
    titleLabel.background.color = .clear
    titleLabel.set(margin: 10~, for: .left)
    titleLabel.verticalArrangement = .center
    titleLabel.height = 100%
    titleLabel.flex = 1
    add(subview: titleLabel)
    
    secondaryLabel.background.color = .clear
    secondaryLabel.set(margin: 10~, for: .right)
    secondaryLabel.verticalArrangement = .center
    secondaryLabel.horizontalArrangement = .right
    secondaryLabel.height = 100%
    secondaryLabel.width = 60~
    add(subview: secondaryLabel)
    
    updateAppearance(style: Appearance.current)
  }
  
  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    background.color = isHighlighted ? .highlightedCellColor : .backgroundColor
    titleLabel.textColor = isHighlighted ? .white : .textColor
    secondaryLabel.textColor = isHighlighted ? .white : .textColor
  }
}
