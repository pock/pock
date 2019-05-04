//
//  ControlCenterVolumeDownItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCVolumeDownItem: ControlCenterItem {
    
    private let key: KeySender = KeySender(keyCode: NX_KEYTYPE_SOUND_DOWN, isAux: true)
    
    override var title: String  { return "volume-down" }
    
    override var icon:  NSImage { return NSImage(named: NSImage.touchBarVolumeDownTemplateName)! }
    
    override func action() {
        key.send()
    }

}
