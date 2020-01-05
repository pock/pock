//
//  CCVolumeToggleItem.swift
//  Pock
//
//  Created by Licardo on 2019/11/4.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class CCVolumeToggleItem: ControlCenterItem {
    
    override var enabled: Bool { return Defaults[.shouldShowVolumeItem] && Defaults[.shouldShowVolumeToggleItem] }
    
    override var title: String { return "volume-toggle" }
    
    override var icon: NSImage {
        if Defaults[.isVolumeMute] {
            return NSImage(named: NSImage.touchBarAudioOutputVolumeOffTemplateName)!
        } else {
            Defaults[.isVolumeMute] = false
            switch NSSound.systemVolume() {
            case 0.01..<0.375:
                return NSImage(named: NSImage.touchBarAudioOutputVolumeLowTemplateName)!
            case 0.375..<0.6875:
                return NSImage(named: NSImage.touchBarAudioOutputVolumeMediumTemplateName)!
            case 0.6875...1.0:
                return NSImage(named: NSImage.touchBarAudioOutputVolumeHighTemplateName)!
            default:
                return NSImage(named: NSImage.touchBarAudioOutputVolumeOffTemplateName)!
            }
        }
    }
    
    override func action() -> Any? {
        parentWidget?.showSlideableController(for: self, currentValue: NSSound.systemVolume())
    }
    
    override func longPressAction() {
        parentWidget?.showSlideableController(for: self, currentValue: NSSound.systemVolume())
    }
    
    override func didSlide(at value: Double) {
        Defaults[.isVolumeMute] = false
        NSSound.setSystemVolume(Float(value))
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadControlCenterWidget, object: nil)
        // DK_OSDUIHelper.showHUD(type: NSSound.isMuted() ? .mute : .volume, filled: CUnsignedInt(NSSound.systemVolume() * 16))
    }
    
}
