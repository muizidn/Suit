//
//  FileListComponent.swift
//  Suit
//
//  Created by pmacro  on 15/03/2019.
//

import Foundation

///
/// Component that displays a list of files.
///
public class FileListComponent: ListComponent {
  
  var currentDirectory: URL?  
  var highlightedFile: URL?
  
  var currentDirectoryChildren: [URL]?
  
  let onSelection: FileSelectionAction
  let onCancel: FileSelectionCancellationAction?
  let directoryFilter: FileSelectionDirectoryFilter?
  let permittedFileTypes: [String]
  let isSelectingDirectory: Bool

  public init(fileOfType types: [String],
              onSelection: @escaping FileSelectionAction,
              onCancel: FileSelectionCancellationAction?,
              directoryFilter: FileSelectionDirectoryFilter?) {
    self.permittedFileTypes = types
    self.onSelection = onSelection
    self.onCancel = onCancel
    self.directoryFilter = directoryFilter
    self.isSelectingDirectory = types.isEmpty
    super.init()
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    listView?.isSelectable = true
    listView?.datasource = self
    
    listView?.onSelection = { [weak self] indexPath, cell in
      if let cell = cell as? FileListItemCell, let selectedURL = cell.url {
        if selectedURL.hasDirectoryPath {
          self?.show(directory: selectedURL)
        } else if cell.isSelectable {
          self?.onSelection([selectedURL])
          self?.view.window.close()
        }
      }
    }
    
    listView?.onHighlight = { [weak self] indexPath, cell in
      if let cell = cell as? FileListItemCell {
        self?.highlightedFile = cell.url
      }
    }
  }
  
  override public func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    view.background.color = .textAreaBackgroundColor
  }
  
  func popDirectory() {
    currentDirectory = currentDirectory?.deletingLastPathComponent().standardizedFileURL
    reload()
  }
  
  func show(directory: URL) {
    guard directory.hasDirectoryPath else { return }
    
    currentDirectory = directory
    reload()
  }
  
  override public func reload() {
    defer { 
      super.reload() 
      listView?.embeddingScrollView?.scrollToTop()
    }
    
    guard let currentDirectory = currentDirectory else {
      currentDirectoryChildren = nil
      return
    }
    print("currentDirectory = \(currentDirectory)")

    currentDirectoryChildren =
      try? FileManager.default.contentsOfDirectory(atPath: currentDirectory.path)
        .map { currentDirectory.appendingPathComponent($0) }
        .sorted(by: { (lhs, rhs) -> Bool in
          return lhs.lastPathComponent < rhs.lastPathComponent
        })
  }
  
  public override func numberOfSections() -> Int {
    return 1
  }
  
  public override func numberOfItemsInSection(section: Int) -> Int {
    return currentDirectoryChildren?.count ?? 0
  }

  public override func cellForItem(at indexPath: IndexPath, withState state: ListItemState) -> ListViewCell {
    let cell = FileListItemCell()
    cell.isHighlighted = state.isHighlighted
    cell.url = currentDirectoryChildren?[indexPath.item]
    let title = cell.url?.lastPathComponent ?? ""
    cell.label.text = title
    cell.width=100%

    if let type = cell.url?.lastPathComponent, !permittedFileTypes.isEmpty {
      cell.isSelectable = permittedFileTypes
                          .contains(where: { ("/" + type).hasSuffix($0) })
    } else {
      cell.isSelectable = isSelectingDirectory && cell.url?.hasDirectoryPath == true
    }
        
    return cell
  }
  
  public override func heightOfCell(at indexPath: IndexPath) -> CGFloat {
    return 20
  }
}

class FileListItemCell: ListViewCell {
  
  let icon = ImageView()
  let label = Label()
  var url: URL? {
    didSet {
      if let url = url {
        icon.image = IconService.icon(forFile: url.path)
      }
    }
  }
  var isSelectable = true
  
  override func didAttachToWindow() {
    super.didAttachToWindow()
    flexDirection = .row
    alignItems = .center
    
    set(padding: 5~, for: .left)

    icon.height = 75%
    icon.aspectRatio = 1
    add(subview: icon)
    
    label.set(margin: 5~, for: .left)
    label.height = 100%
    label.width = 100%
    label.verticalArrangement = .center
    label.background.color = .clear

    updateAppearance(style: Appearance.current)
    add(subview: label)
  }
  
  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    
    if isHighlighted {
      label.textColor = isSelectable ? .white : .gray
      background.color = .highlightedCellColor
    } else {
      label.textColor = isSelectable ? .textColor : .gray
      background.color = .textAreaBackgroundColor
    }
  }
}
