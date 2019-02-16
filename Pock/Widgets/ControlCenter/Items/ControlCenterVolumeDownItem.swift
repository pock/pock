//
//  ControlCenterVolumeDownItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class ControlCenterVolumeDownItem: ControlCenterItem {
    
    override var title: String  { return "volume-down" }
    
    override var icon:  NSImage { return NSImage(named: .touchBarVolumeDownTemplate)! }
    
    override func action() {
        NSSound.decreaseSystemVolume(by: 0.06)
        DK_OSDUIHelper.showHUD(type: NSSound.systemVolume() < 0.06 ? .mute : .volume, filled: CUnsignedInt(NSSound.systemVolume() * 16))
    }

}
