//
//  FileBrowserComponent.swift
//  Suit
//
//  Created by pmacro  on 15/03/2019.
//

import Foundation

///
/// A component that presents a file browsing interface, and which allows for the selection
/// of a file or folder.
///
public class FileBrowserComponent: CompositeComponent {
  
  /// The component that displays the list of files in a given directory.
  let fileListComponent: FileListComponent
  
  ///
  /// Opens the file browser component according to the supplied configuration.
  ///
  public static func open(fileOfType types: [String],
                          onSelection: @escaping FileSelectionAction,
                          onCancel: FileSelectionCancellationAction?,
                          directoryFilter: FileSelectionDirectoryFilter?) {
    
    let component = FileBrowserComponent(fileOfType: types,
                                         onSelection: onSelection,
                                         onCancel: onCancel,
                                         directoryFilter: directoryFilter)
    
    let window = Window(rootComponent: component,
                        frame: CGRect(x: 0, y: 0, width: 600, height: 400))
    window.center()
    Application.shared.add(window: window)
    window.bringToFront()
    window.setAlwaysOnTop()
  }
  
  public init(fileOfType types: [String],
              onSelection: @escaping FileSelectionAction,
              onCancel: FileSelectionCancellationAction?,
              directoryFilter: FileSelectionDirectoryFilter?) {
    fileListComponent = FileListComponent(fileOfType: types,
                                          onSelection: onSelection,
                                          onCancel: onCancel,
                                          directoryFilter: directoryFilter)
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.width = 100%
    view.height = 100%
    
    let backButton = Button(ofType: .titleBarButton)
    backButton.set(margin: 10~, for: .left)
    backButton.height = 20~
    backButton.width = 20~

    if let imagePath = Bundle.main.path(forAsset: "back", ofType: "png") {
      backButton.set(image: Image(filePath: imagePath))
      backButton.alignContent = .center
      backButton.justifyContent = .center
      backButton.imageView.width = 14~
      backButton.imageView.useImageAsMask = true
      backButton.imageView.tintColor = .white
    }

    backButton.onPress = { [weak self] in
      self?.fileListComponent.popDirectory()
    }
    view.window.titleBar?.additionalContentView.add(subview: backButton)
    
    createHeader()
    
    add(component: fileListComponent)
    fileListComponent.view.width = 100%
    fileListComponent.view.flex = 1
    
    let divider = View()
    divider.width = 100%
    divider.height = 1~
    divider.background.color = .lightGray
    view.add(subview: divider)

    let buttonBarComponent = Component()
    buttonBarComponent.view.flexDirection = .row
    add(component: buttonBarComponent)
    buttonBarComponent.view.height = 38~
    buttonBarComponent.view.width = 100%
    buttonBarComponent.view.background.color = .backgroundColor
    buttonBarComponent.view.alignItems = .center
    buttonBarComponent.view.justifyContent = .flexEnd
    buttonBarComponent.view.set(padding: 10~, for: .right)
    
    let cancelButton = Button(ofType: .rounded)
    cancelButton.width = 80~
    cancelButton.height = 21~
    cancelButton.title = "Cancel"
    cancelButton.set(margin: 10~, for: .right)
    buttonBarComponent.view.add(subview: cancelButton)
    cancelButton.onPress = { [weak self] in
      self?.view.window.close()
    }

    let openButton = Button(ofType: .rounded)
    openButton.width = 80~
    openButton.height = 21~
    openButton.title = "Open"

    buttonBarComponent.view.add(subview: openButton)
    openButton.onPress = { [weak self] in
      let selection = self?.fileListComponent.currentDirectory
                   ?? self?.fileListComponent.highlightedFile
      
      if let selection = selection {
        self?.fileListComponent.onSelection([selection])
        self?.view.window.close()
      }
    }
    
    print("Opening file browser in directory: \(FileManager.default.homeDirectoryForCurrentUser)")
    fileListComponent.show(directory: FileManager.default.homeDirectoryForCurrentUser)
  }
  
  func createHeader() {
    let header = View()
    header.background.color = .backgroundColor
    header.width = 100%
    header.height = 22~
    header.set(padding: 10~, for: .left)
    view.add(subview: header)
    
    let titleLabel = Label(text: "Name")
    titleLabel.height = 100%
    titleLabel.flex = 1
    titleLabel.verticalArrangement = .center
    titleLabel.font = .ofType(.system, category: .smallMedium)
    header.add(subview: titleLabel)
    
    let headerDivider = View()
    headerDivider.width = 100%
    headerDivider.height = 0.5~
    headerDivider.background.color = .lightGray
    view.add(subview: headerDivider)
  }
}
