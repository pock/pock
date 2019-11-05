import Foundation
import Defaults

class CCVolumeMuteItem: ControlCenterItem {
    
    override var enabled: Bool{ return Defaults[.shouldShowVolumeItem] && Defaults[.shouldShowVolumeMuteItem] }
    
    private let key: KeySender = KeySender(keyCode: NX_KEYTYPE_MUTE, isAux: true)
    
    override var title: String  { return "volume-mute" }
    
    override var icon: NSImage {
        return NSImage(named: NSSound.isMuted() ? title : NSImage.touchBarAudioOutputMuteTemplateName)!
    }
    
    override func action() -> Any? {
        key.send()
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadControlCenterWidget, object: nil)
        return NSSound.systemVolume()
    }
    
}
