//
//  ControlCenterVolumeUpItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCVolumeUpItem: ControlCenterItem {
    
    override var title: String  { return "volume-up" }
    
    override var icon:  NSImage { return NSImage(named: NSImage.touchBarVolumeUpTemplateName)! }
    
    override func action() {
        NSSound.increaseSystemVolume(by: 0.06)
        if !(NowPlayingHelper.shared.nowPlayingItem?.isPlaying ?? true) {
            NSSound.beep()
        }
        DK_OSDUIHelper.showHUD(type: .volume, filled: CUnsignedInt(NSSound.systemVolume() * 16))
    }
    
}
