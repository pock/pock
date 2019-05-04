//
//  CCBrightnessDownItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCBrightnessDownItem: ControlCenterItem {

    private let key: KeySender = KeySender(keyCode: NX_KEYTYPE_BRIGHTNESS_DOWN, isAux: true)
    
    override var title: String  { return "brightness-down" }
    
    override var icon:  NSImage { return NSImage(named: title)! }
    
    override func action() {
        key.send()
    }
    
}
