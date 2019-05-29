//
// Created by pmacro on 29/05/19.
//

#if os(Linux)

import Foundation
import X11

///
/// Utility class for querying the system for information about a 
/// display.
///
class DisplayUtils {

  /// The DPI we consider as "native", i.e. a screen with this DPI will not be scaled.
  static let baselineDPI: CGFloat = 96

  ///
  /// Gets the scale factor that should be applied when rendering to the provided display.
  ///
  static func getScaleFactor(forDisplay display: OpaquePointer!) -> CGFloat {
    return getDPI(forDisplay: display) / baselineDPI
  }

  ///
  /// Retrieves the DPI for a given display.
  ///
  static func getDPI(forDisplay display: OpaquePointer!) -> CGFloat {
    let resourceString = XResourceManagerString(display)

    let db = XrmGetStringDatabase(resourceString)
    var value = XrmValue()
    var type: UnsafeMutablePointer<Int8>? = nil

    // Need to initialize the DB before calling Xrm* functions.
    XrmInitialize()

    if resourceString != nil {
      if (XrmGetResource(db, "Xft.dpi", "String", &type, &value) == 1) {
        if let dpiVal = value.addr {
          let dpiString = String(cString: dpiVal)
          if let dpiDouble = Double(dpiString) {
            return CGFloat(dpiDouble)
          }
        }
      }
    }

    return baselineDPI
  }
}

#endif

