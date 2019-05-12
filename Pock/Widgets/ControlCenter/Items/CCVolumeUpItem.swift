//
//  ControlCenterVolumeUpItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCVolumeUpItem: ControlCenterItem {
    
    private let key: KeySender = KeySender(keyCode: NX_KEYTYPE_SOUND_UP, isAux: true)
    
    override var title: String  { return "volume-up" }
    
    override var icon:  NSImage { return NSImage(named: NSImage.touchBarVolumeUpTemplateName)! }
    
    override func action() {
        key.send()
    }
    
    override func longPressAction() {
        parentWidget?.showSlideableController(for: self)
    }
    
}
