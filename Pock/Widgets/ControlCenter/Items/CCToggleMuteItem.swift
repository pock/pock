import Foundation
import Defaults

class CCToggleMuteItem: ControlCenterItem {
  
  override var enabled: Bool{ return Defaults[.shouldShowVolumeItem] && Defaults[.shouldShowToggleMuteItem] }
  
  private let key: KeySender = KeySender(keyCode: NX_KEYTYPE_MUTE, isAux: true)
  
  override var title: String  { return "toggle-mute" }
  
  override var icon:  NSImage { return NSImage(named: NSImage.touchBarAudioOutputMuteTemplateName)! }
  
  override func action() -> Any? {
    key.send()
    return NSSound.systemVolume()
  }
  
  override func longPressAction() {
    parentWidget?.showSlideableController(for: self, currentValue: NSSound.systemVolume())
  }
  
  override func didSlide(at value: Double) {
    NSSound.setSystemVolume(Float(value))
    // DK_OSDUIHelper.showHUD(type: NSSound.isMuted() ? .mute : .volume, filled: CUnsignedInt(NSSound.systemVolume() * 16))
  }
  
}
