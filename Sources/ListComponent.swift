//
//  CollectionComponent.swift
//  Suit
//
//  Created by pmacro on 18/01/2017.
//
//

import Foundation

open class ListComponent: Component, ListViewDatasource {

  open var listView: ListView?

  open var datasource: ListViewDatasource? {
    didSet {
      listView?.datasource = datasource
    }
  }
  
  override open func loadView() {
    view = ScrollView()
  }

  open override func viewDidLoad() {
    super.viewDidLoad()

    listView = ListView()
    listView?.background.color = .backgroundColor
    view.add(subview: listView!)
    datasource = datasource ?? self
  }

  open func reload() {
    if let listView = listView, let scrollView = view as? ScrollView {
      let rect = CGRect(origin: scrollView.contentWrapper.bounds.origin,
                        size: scrollView.frame.size)
      listView.didScroll(to: rect)
      listView.scrollTo(itemAt: IndexPath(item: 0, section: 0))
      view.forceRedraw()
    }
  }

  func visibleRowRange(forSection section: Int) -> Range<Int> {
    return 0..<0
  }

  /// ListViewDatasource

  open func numberOfSections() -> Int {
    return 0
  }

  open func numberOfItemsInSection(section: Int) -> Int {
    return 0
  }

  open func cellForItem(at indexPath: IndexPath,
                        withState state: ListItemState) -> ListViewCell {
    return ListViewCell()
  }

  open func heightOfCell(at indexPath: IndexPath) -> CGFloat {
    return 20
  }
}
