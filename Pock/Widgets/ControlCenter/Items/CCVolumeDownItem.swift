//
//  ControlCenterVolumeDownItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCVolumeDownItem: ControlCenterItem {
    
    override var title: String  { return "volume-down" }
    
    override var icon:  NSImage { return NSImage(named: .touchBarVolumeDownTemplate)! }
    
    override func action() {
        NSSound.decreaseSystemVolume(by: 0.06)
        NSSound.beep()
        DK_OSDUIHelper.showHUD(type: NSSound.isMuted() ? .mute : .volume, filled: CUnsignedInt(NSSound.systemVolume() * 16))
    }

}
