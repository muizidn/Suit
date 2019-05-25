//
//  WeakBox.swift
//  Editor
//
//  Created by pmacro  on 30/01/2019.
//

import Foundation

final class WeakBox<A: AnyObject> {
  weak var unbox: A?
  init(_ value: A) {
    unbox = value
  }
}

struct WeakArray<Element: AnyObject> {
  private var items: [WeakBox<Element>] = []
  
  var last: Element? {
    return items.last?.unbox
  }
  
  init(_ elements: [Element]) {
    items = elements.map { WeakBox($0) }
  }
  
  mutating func append(_ newElement: Element) {
    items.append(WeakBox(newElement))
  }
  
  mutating func removeAll() {
    items.removeAll()
  }
  
  mutating func removeAll(where condition: (Element) throws -> Bool) {
    try? items.removeAll { (boxed) -> Bool in
      return try boxed.unbox == nil || condition(boxed.unbox!)
    }
  }
}

extension WeakArray: Collection {
  var startIndex: Int { return items.startIndex }
  var endIndex: Int { return items.endIndex }
  
  subscript(_ index: Int) -> Element? {
    return items[index].unbox
  }
  
  func index(after idx: Int) -> Int {
    return items.index(after: idx)
  }
}
