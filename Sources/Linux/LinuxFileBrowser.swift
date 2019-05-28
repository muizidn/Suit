//
//  LinuxFileBrowser.swift
//  Editor
//
//  Created by pmacro  on 29/01/2019.
//

#if os(macOS)

import Foundation

extension FileBrowser {
  
  static public func selectDirectory(onSelection: @escaping FileSelectionAction,
                                     onCancel: FileSelectionCancellationAction?) {
    FileBrowserComponent.open(fileOfType: [],
                              onSelection: onSelection,
                              onCancel: onCancel,
                              directoryFilter: nil)
  }
  
  static public func open(fileOfType types: [String],
                          onSelection: @escaping FileSelectionAction,
                          onCancel: FileSelectionCancellationAction?,
                          directoryFilter: FileSelectionDirectoryFilter?) {
    FileBrowserComponent.open(fileOfType: types,
                              onSelection: onSelection,
                              onCancel: onCancel,
                              directoryFilter: directoryFilter)
  }
}

#endif
