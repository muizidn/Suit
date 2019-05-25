//
//  LinuxIconService.swift
//  Suit
//
//  Created by pmacro on 15/05/2019.
//

#if os(Linux)

import Foundation

///
/// TODO
///
/// This is a toy implementation for now.  The linux icon spec is much
/// more complex than this code accounts for, and this will certainly
/// only work on some systems and some theme configurations.
///
class LinuxIconService {
  // The name of the theme to use when looking up icons.
  var themeName: String = ""
  // Icon file names keyed by the mime type.
  var mimeTypeToFileName = [String : String]()
  // Mime type keyed by file extension.
  var fileTypeToMimeType = [String : String]()
  
  init() {
    themeName = queryGtkThemeName() ?? "Yaru"
    print("Using icon theme: '\(themeName)'")
    
    readFileToMimeTypeMapping()
    readMimeTypeAssociations()
  }
  
  func readFileToMimeTypeMapping() {
    let file = URL(fileURLWithPath: "/etc/mime.types")
    let contents = try! String(contentsOf: file)
    let lines = contents.split(separator: "\n")
    
    lines.forEach {
      if $0.hasPrefix("#") { return }
      
      let mapping = $0.components(separatedBy: .whitespaces)
      if mapping.count == 2 {
        fileTypeToMimeType[String(mapping[1])] = String(mapping[0])
      }
    }
  }
  
  func readMimeTypeAssociations() {
    let directory = URL(fileURLWithPath: "/usr/share/mime")
    let genericIconsFile = directory.appendingPathComponent("generic-icons")
    
    let genericIcons = try! String(contentsOf: genericIconsFile)
    genericIcons.split(separator: "\n").forEach {
      if $0.hasPrefix("#") { return }
      
      let keyAndValue = $0.split(separator: ":")
      if keyAndValue.count == 2 {
        let key = String(keyAndValue[0])
        mimeTypeToFileName[key] = String(keyAndValue[1])
      }
    }
  }
  
  func icon(forFile path: String, size: String = "32x32") -> Image? {
    let fileURL = URL(fileURLWithPath: path)
    
    if fileURL.hasDirectoryPath {
      let iconName = mimeTypeToFileName["inode/directory"] ?? "folder"
      return Image(filePath:
        "/usr/share/icons/\(themeName)/\(size)/places/\(iconName).png")
    }
    
    let fileType = fileURL.pathExtension
    let mimeType = fileTypeToMimeType[fileType]
    
    var iconName = "text-x-generic" // fallback
    
    if let mimeType = mimeType {
      iconName = mimeTypeToFileName[mimeType] ?? iconName
    }
    
    return Image(filePath:
      "/usr/share/icons/\(themeName)/\(size)/mimetypes/\(iconName).png")
  }
  
  func queryGtkThemeName() -> String? {
    let process = Process()
    process.launchPath = "/usr/bin/gsettings"
    process.arguments = ["get",
                         "org.gnome.desktop.interface",
                         "icon-theme"]
    
    let output = Pipe()
    process.standardOutput = output
    try? process.run()
    
    let data = output.fileHandleForReading.readDataToEndOfFile()
    var charSet = CharacterSet.whitespacesAndNewlines
    // The name is enclosed within single quotes, which we need to remove.
    charSet.insert(charactersIn: "'")
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: charSet)
  }
}
#endif
