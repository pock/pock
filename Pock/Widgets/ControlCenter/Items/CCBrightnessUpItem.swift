//
//  CCBrightnessUpItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCBrightnessUpItem: ControlCenterItem {
    
    private let key: KeySender = KeySender(keyCode: NX_KEYTYPE_BRIGHTNESS_UP, isAux: true)
    
    override var title: String  { return "brightness-up" }
    
    override var icon:  NSImage { return NSImage(named: title)! }
    
    override func action() {
        key.send()
    }
    
}
