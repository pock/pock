//
//  CCBrightnessUpItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCBrightnessUpItem: ControlCenterItem {
    
    override var title: String  { return "brightness-up" }
    
    override var icon:  NSImage { return NSImage(named: NSImage.Name(title))! }
    
    override func action() {
        DKBrightness.increaseBrightness(by: 0.06)
        DK_OSDUIHelper.showHUD(type: .brightness, filled: CUnsignedInt(DKBrightness.getBrightnessLevel() * 16))
    }
    
}
