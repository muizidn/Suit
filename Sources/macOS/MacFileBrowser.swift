//
//  MacFileBrowser.swift
//  Suit
//
//  Created by pmacro on 22/06/2018.
//

#if os(Linux)

import Foundation
import AppKit

extension FileBrowser {
  
  static public func selectDirectory(onSelection: @escaping FileSelectionAction,
                                     onCancel: FileSelectionCancellationAction?) {
    let dialog = NSOpenPanel()
    dialog.showsResizeIndicator    = true
    dialog.showsHiddenFiles        = true
    dialog.canChooseDirectories    = true
    dialog.canCreateDirectories    = true
    dialog.allowsMultipleSelection = false
    dialog.canChooseFiles = false

    if (dialog.runModal() == NSApplication.ModalResponse.OK) {
      if let url = dialog.url {
        onSelection([url])
      }
    } else {
      // User clicked on "Cancel"
      onCancel?()
      return
    }
  }

  static public func open(fileOfType types: [String],
                          onSelection: @escaping FileSelectionAction,
                          onCancel: FileSelectionCancellationAction?,
                          directoryFilter: FileSelectionDirectoryFilter?) {
    
    let dialog = NSOpenPanel()
    let delegate = OpenSaveDelegate(allowedTypes: types,
                                    directoryFilter: directoryFilter)
    dialog.delegate = delegate
    dialog.showsResizeIndicator    = true
    dialog.showsHiddenFiles        = true
    dialog.canChooseDirectories    = true
    dialog.canCreateDirectories    = true
    dialog.allowsMultipleSelection = false
    
    if (dialog.runModal() == NSApplication.ModalResponse.OK) {
      if let url = dialog.url {
        onSelection([url])
      }
    } else {
      // User clicked on "Cancel"
      onCancel?()
      return
    }
  }
}

class OpenSaveDelegate: NSObject, NSOpenSavePanelDelegate {
  
  let allowedTypes: [String]
  let directoryFilter: FileSelectionDirectoryFilter?
  
  init(allowedTypes: [String], directoryFilter: FileSelectionDirectoryFilter?) {
    self.allowedTypes = allowedTypes
    self.directoryFilter = directoryFilter
  }
  
  func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
    let path = url.path
    
    if url.hasDirectoryPath {
      if let directoryFilter = directoryFilter {
        return directoryFilter(url)
      }
    }
    
    for type in allowedTypes {
      // No directories, except ones with file-like extensions.
      if (!url.hasDirectoryPath || type.hasPrefix("."))
        && path.hasSuffix(type) {
        return true
      }
    }
    return false
  }
}
#endif
