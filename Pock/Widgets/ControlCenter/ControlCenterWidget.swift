//
//  ControlCenterWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class ControlCenterWidget: PockWidget {
    
    /// Core
    fileprivate let controls: [ControlCenterItem] = [
        CCBrightnessDownItem(),
        CCBrightnessUpItem(),
        CCVolumeDownItem(),
        CCVolumeUpItem()
    ]
    
    /// UI
    fileprivate var segmentedControl: NSSegmentedControl!
    
    override func customInit() {
        self.customizationLabel = "Control Center"
        self.initializeSegmentedControl()
        self.set(view: segmentedControl)
    }
    
    private func initializeSegmentedControl() {
        let items = controls.map({ $0.icon }) as [NSImage]
        segmentedControl = NSSegmentedControl(images: items, trackingMode: .momentary, target: self, action: #selector(tap(_:)))
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.autoresizingMask = [.width, .height]
        controls.enumerated().forEach({ index, _ in
            segmentedControl.setWidth(50, forSegment: index)
        })
    }
    
    @objc private func tap(_ sender: NSSegmentedControl) {
        controls[sender.selectedSegment].action()
    }
}
