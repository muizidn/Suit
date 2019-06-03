import Foundation
import GD

/// Represents a colour channel within an image.
fileprivate enum ColorChannel {
  case red
  case green
  case blue
  case alpha
}

///
/// Loads icons suitable for passing directly to X11.
///
class IconLoader {

  ///
  /// For a GD image, and given an Int32 containing the colour information for a single pixel, 
  /// returns the colour information for a particular channel (rgba).
  ///
  fileprivate static func getColor(from icon: gdImageStruct, pixelColour: Int32, channel: ColorChannel) -> Int32 {
    if icon.trueColor == 1 {
      switch channel {
        case .red:
          return (pixelColour & 0xFF0000) >> 16
        case .green:
          return (pixelColour & 0x00FF00) >> 8
        case .blue:
          return pixelColour & 0x0000FF
        case .alpha:
          return (pixelColour & 0x7F000000) >> 24
      }
    }

    // This type is a massively long Tuple.  Pre-setting to blue as an easy way to have
    // tmp be the correct type.
    var tmp = icon.blue

    switch channel {
      case .red:
        tmp = icon.red
      case .green:
        tmp = icon.green
      case .blue:
        tmp = icon.blue
      case .alpha:
        tmp = icon.alpha
    }

    let array = [Int32](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))  
    return array[Int(pixelColour)]
  }

  ///
  /// Loads the icon from the given path into a CUnsignedLong array, suitable for use with X.
  ///
  static func loadIcon(from path: String) -> [CUnsignedLong]? {
    guard let cPath = path.cString(using: .utf8),
      let iconFile = fopen(cPath, "r") else {
        print("Couldn't read icon from path: \(path)")
        return nil
    }

    defer { fclose(iconFile) }

    let iconPtr = gdImageCreateFromPng(iconFile)

    guard let icon = iconPtr?.pointee else {
      print("Unable to read image data from file: \(path)")
      return nil
    }

    let width = icon.sx
    let height = icon.sy

    var imageData = [CUnsignedLong]()
    imageData.append(CUnsignedLong(width))
    imageData.append(CUnsignedLong(height))

    for y in 0..<height {
      for x in 0..<width {
        // The image is RGBA, but we need to make it BGRA.
        let pixcolour = (gdImageGetPixel(iconPtr, x, y))

        // Get each the colour value for each channel within the pixel.
        let red = UInt32(getColor(from: icon, pixelColour: pixcolour, channel: .red))
        let green = UInt32(getColor(from: icon, pixelColour: pixcolour, channel: .green))
        let blue = UInt32(getColor(from: icon, pixelColour: pixcolour, channel: .blue))
        var alpha = 127 - UInt32(getColor(from: icon, pixelColour: pixcolour, channel: .alpha))

        if alpha == 127 {
          alpha = 255
        } else {
          alpha *= 2
        }

        // Shove all the channels back into a single pixel value, this time
        // stored as BGRA.
        var pix = alpha
        pix = pix << 8
        pix |= red
        pix = pix << 8
        pix |= green
        pix = pix << 8
        pix |= blue
        imageData.append(CUnsignedLong(truncatingIfNeeded: pix))
      }
    }

    gdImageDestroy(iconPtr)
    return imageData
  }
}







































































































































































































































































































































































//
