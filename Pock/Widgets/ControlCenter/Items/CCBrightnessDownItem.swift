//
//  CCBrightnessDownItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCBrightnessDownItem: ControlCenterItem {
    
    override var title: String  { return "brightness-down" }
    
    override var icon:  NSImage { return NSImage(named: NSImage.Name(title))! }
    
    override func action() {
        DKBrightness.decreaseBrightness(by: 0.06)
        DK_OSDUIHelper.showHUD(type: .brightness, filled: CUnsignedInt(DKBrightness.getBrightnessLevel() * 16))
    }
    
}
