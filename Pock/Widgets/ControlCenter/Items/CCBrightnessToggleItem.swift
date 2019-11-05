//
//  CCBrightnessToggleItem.swift
//  Pock
//
//  Created by Licardo on 2019/11/4.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class CCBrightnessToggleItem: ControlCenterItem {

    override var enabled: Bool{ return Defaults[.shouldShowBrightnessItem] && Defaults[.shouldShowBrightnessToggleItem] }
    
    override var title: String  { return "brightness-toggle" }
    
    override var icon:  NSImage { return NSImage(named: title)! }
    
    override func action() -> Any? {
        parentWidget?.showSlideableController(for: self, currentValue: DKBrightness.getBrightnessLevel())
    }
    
    override func longPressAction() {
           parentWidget?.showSlideableController(for: self, currentValue: DKBrightness.getBrightnessLevel())
    }
    
    override func didSlide(at value: Double) {
        DKBrightness.setBrightnessLevel(level: Float(value))
        DK_OSDUIHelper.showHUD(type: .brightness, filled: CUnsignedInt(DKBrightness.getBrightnessLevel() * 16))
    }
    
}

