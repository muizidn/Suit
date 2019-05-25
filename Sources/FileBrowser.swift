//
//  FileBrowser.swift
//  Suit
//
//  Created by pmacro on 22/06/2018.
//

import Foundation

public typealias FileSelectionAction = (_ selectedFileURLs: [URL]) -> Void
public typealias FileSelectionCancellationAction = () -> Void
public typealias FileSelectionDirectoryFilter = (_ directory: URL) -> Bool

public protocol PlatformFileBrowser {
  static func open(fileOfType types: [String],
                   onSelection: @escaping FileSelectionAction)
  
  static func open(fileOfType types: [String],
                   onSelection: @escaping FileSelectionAction,
                   onCancel: FileSelectionCancellationAction?)
  
  static func open(fileOfType types: [String],
                   onSelection: @escaping FileSelectionAction,
                   onCancel: FileSelectionCancellationAction?,
                   directoryFilter: FileSelectionDirectoryFilter?)

}

public struct FileBrowser: PlatformFileBrowser {
  
  static public func open(fileOfType types: [String],
                          onSelection: @escaping FileSelectionAction,
                          onCancel: FileSelectionCancellationAction?) {
    FileBrowser.open(fileOfType: types,
                     onSelection: onSelection,
                     onCancel: onCancel,
                     directoryFilter: nil)
  }

  static public func open(fileOfType types: [String],
                          onSelection: @escaping FileSelectionAction) {
    FileBrowser.open(fileOfType: types, onSelection: onSelection, onCancel: nil)
  }
    
}
