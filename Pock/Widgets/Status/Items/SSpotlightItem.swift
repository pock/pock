//
//  SSpotlightItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults
import Carbon.HIToolbox

struct CommandKeySender: KeySender {
    let keyCode: CGKeyCode = CGKeyCode(kVK_Command)
}
struct SpaceKeySender: KeySender {
    let keyCode: CGKeyCode = CGKeyCode(kVK_Space)
}

class SSpotlightItem: StatusItem {
    
    /// UI
    private let tappableView: StatusItemView = StatusItemView(frame: .zero)
    private let iconView: NSImageView = NSImageView(frame: .zero)
    
    init() {
        iconView.image      = NSImage(named: .touchBarSearchTemplate)!
        tappableView.item   = self
        tappableView.addSubview(iconView)
        iconView.snp.makeConstraints({ maker in
            maker.edges.equalTo(tappableView).inset(2)
        })
    }
    
    var enabled: Bool{ return defaults[.shouldShowSpotlightItem] }
    
    var title: String  { return "spotlight" }
    
    var view: NSView { return tappableView }
    
    func action() {
        // TODO: Must find an alternative way since not everyone has CMD+SPACE shortcut for Spotlight!
        let commandKey  = CommandKeySender()
        let spaceKey    = SpaceKeySender()
        commandKey.press()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
            spaceKey.send()
            commandKey.release()
        })
    }
    
    func reload() { /* Nothing to do here... */ }
}
