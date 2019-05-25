#if os(Linux)

import Foundation
import X11

struct LinuxKeyEvent: KeyEvent {

  var strokeType: KeyStrokeType
  var keyType: KeyType
  var keyCode: UInt16
  var modifiers: [KeyModifiers]?

  var characters: String?

  init(event: XKeyEvent, type: KeyStrokeType) {
    self.keyCode = UInt16(event.keycode)
    self.strokeType = type
    self.modifiers = []
    
    var keySym = KeySym()
    
    var keyEvent = event
    let keyState = Int32(event.state)

     if keyState & ShiftMask != 0 {
       modifiers?.append(.shift)
    }

    if keyState & ControlMask != 0 {
      // Get the string without the control modifier in XLookupstring
      keyEvent.state = 0
      modifiers?.append(.control) 
    }

    var charBuffer = [CChar](repeating: 0, count: 5)
    XLookupString(&keyEvent, &charBuffer, 5, &keySym, nil)
    self.characters = String(cString: &charBuffer)

    if keySym == XK_Control_L || keySym == XK_Control_R {
      self.modifiers?.append(.control)
    }

    switch Int32(keySym) {
      case XK_BackSpace:
        self.keyType = .delete
      case XK_Left:
        self.keyType = .leftArrow
      case XK_Right:
        self.keyType = .rightArrow
      case XK_Up:
        self.keyType = .upArrow
      case XK_Down:
        self.keyType = .downArrow
      case XK_KP_Enter: 
        self.keyType = .enter
       case XK_Return:
        self.keyType = .return
      default:
        self.keyType = .other
    }
  }

  public init(withCharacters characters: String?,
              strokeType: KeyStrokeType,
              modifiers: [KeyModifiers]?,
              keyType: KeyType) {
    self.characters = characters
    self.strokeType = strokeType
    self.modifiers = modifiers ?? []
    self.keyType = keyType
    self.keyCode = 0
  }
}

#endif
