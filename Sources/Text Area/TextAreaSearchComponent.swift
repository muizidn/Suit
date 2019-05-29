//
//  TextAreaSearchComponent.swift
//  StrideLib
//
//  Created by pmacro  on 27/03/2019.
//

import Foundation

///
/// A component that provides searching functionality within a linked TextAreaView.
/// This is configured in TextAreaComponent and as such is not exposed externally
/// outside of Suit.
///
class TextAreaSearchComponent: Component {
  
  let searchBox = TextInputView()
  weak public var textArea: TextAreaView?
  let resultCountLabel = Label()
  
  var resultLimit = 1000

  var activeSearchResults: [Range<String.Index>]?
  var activeSearchTerm: String?
  var highlightedSearchResultIndex: Int?
  
  var isVisible = false

  public override func viewDidLoad() {
    super.viewDidLoad()
    
    view.background.color = .backgroundColor
    view.flexDirection = .row
    view.alignItems = .center
    // Hide by default
    view.height = 0~
    view.width = 100%

    let findLabel = Label(text: "Find")
    findLabel.height = 20~
    findLabel.width = 40~
    findLabel.set(margin: 10~, for: .left)
    
    view.add(subview: findLabel)
    
    searchBox.height = 20~
    searchBox.width = 150~
    
    searchBox.onSubmit = { [weak self] input in
      self?.search(for: input)
    }
    
    view.add(subview: searchBox)
    
    let endSectionWrapper = View()
    endSectionWrapper.height = 100%
    endSectionWrapper.flex = 1

    endSectionWrapper.flexDirection = .rowReverse
    endSectionWrapper.alignItems = .center
    
    let doneButton = Button(ofType: .rounded)
    doneButton.title = "Done"
    doneButton.width = 60~
    doneButton.height = 20~
    doneButton.set(margin: 10~, for: .right)

    doneButton.onPress = { [weak self] in
      self?.toggleVisibility()
    }
    
    endSectionWrapper.add(subview: doneButton)
    
    let nextButton = Button(ofType: .rounded)
    
    if let imagePath = Bundle.main.path(forAsset: "forward", ofType: "png") {
      let image = Image(filePath: imagePath)
      nextButton.set(image: image)
      nextButton.alignContent = .center
      nextButton.justifyContent = .center
      nextButton.imageView.width = 11~
    }

    nextButton.width = 30~
    nextButton.height = 20~
    nextButton.set(margin: 10~, for: .right)
    
    nextButton.onPress = { [weak self] in
      self?.selectNextSearchResult()
    }
    
    endSectionWrapper.add(subview: nextButton)
    
    let previousButton = Button(ofType: .rounded)
    
    if let imagePath = Bundle.main.path(forAsset: "back", ofType: "png") {
      let image = Image(filePath: imagePath)
      previousButton.set(image: image)
      previousButton.alignContent = .center
      previousButton.justifyContent = .center
      previousButton.imageView.width = 11~
    }

    previousButton.width = 30~
    previousButton.height = 20~
    
    previousButton.onPress = { [weak self] in
      self?.selectPreviousSearchResult()
    }
    
    endSectionWrapper.add(subview: previousButton)

    resultCountLabel.width = 100~
    resultCountLabel.height = 20~
    endSectionWrapper.add(subview: resultCountLabel)
    
    view.add(subview: endSectionWrapper)
  }
  
  func search(for term: String) {
    guard let textArea = textArea else { return }
    
    if activeSearchTerm != term {
      activeSearchResults = textArea.state.text.find(searchTerm: term, limit: resultLimit)
      activeSearchTerm = term
    }
    
    let resultCount = (activeSearchResults?.count ?? 0)
    let labelText: String
      
    if resultCount == 1 {
      labelText = "1 result"
    } else {
      labelText = resultCount == resultLimit ? "\(resultCount)+ results"
                                             : "\(resultCount) results"
    }
    
    resultCountLabel.text = labelText
    resultCountLabel.forceRedraw()
    selectNextSearchResult()
  }
  
  func selectNextSearchResult() {
    guard let activeSearchResults = activeSearchResults,
      !activeSearchResults.isEmpty else { return }
    
    var index = highlightedSearchResultIndex ?? -1
    index += 1
    
    if index >= activeSearchResults.count {
      index = 0
    }
    
    selectResult(at: index)
  }
  
  func selectPreviousSearchResult() {
    guard let activeSearchResults = activeSearchResults,
      !activeSearchResults.isEmpty else { return }
    
    var index = highlightedSearchResultIndex ?? activeSearchResults.count
    index -= 1
    
    if index <= 0 {
      index = activeSearchResults.count - 1
    }

    selectResult(at: index)
  }

  func selectResult(at index: Int) {
    guard let activeSearchResults = activeSearchResults,
      !activeSearchResults.isEmpty else { return }

    highlightedSearchResultIndex = index
    
    let range = activeSearchResults[index]
    if let line = textArea?.convertOffsetToLinePosition(range.lowerBound)?.line {
      textArea?.scroll(toLine: line)
      textArea?.select(range: range)
    }
  }
  
  func toggleVisibility() {
    if isVisible {
      view.animate(duration: 0.25,
                   easing: .quadraticEaseIn,
                   changes: {
        view.height = 0~
      })
    } else {
      searchBox.makeKeyView()
      view.animate(duration: 0.25,
                   easing: .quadraticEaseOut,
                   changes: {
        view.height = 30~
      })
    }
    isVisible.toggle()
    view.window.rootView.invalidateLayout()
    view.forceRedraw()
  }
}
