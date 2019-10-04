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

class SSpotlightItem: StatusItem {
    
    /// UI
    private var tappableView: StatusItemView! = StatusItemView(frame: .zero)
    private var iconView: NSImageView! = NSImageView(frame: .zero)
    
    init() {
        didLoad()
    }
    
    deinit {
        didUnload()
    }
    
    func didLoad() {
        iconView.image      = NSImage(named: NSImage.touchBarSearchTemplateName)!
        tappableView.item   = self
        tappableView.addSubview(iconView)
        iconView.snp.makeConstraints({ maker in
            maker.edges.equalTo(tappableView).inset(2)
        })
    }
    
    func didUnload() {
        iconView.image    = nil
        iconView          = nil
        tappableView.item = nil
        tappableView      = nil
    }
    
    var enabled: Bool{ return Defaults[.shouldShowSpotlightItem] }
    
    var title: String  { return "spotlight" }
    
    var view: NSView { return tappableView }
    
    func action() {
        // TODO: maybe...
    }
    
    func reload() { /* Nothing to do here... */ }
}
