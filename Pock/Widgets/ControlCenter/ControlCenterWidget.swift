//
//  ControlCenterWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class PressableSegmentedControl: NSSegmentedControl {
    
    /// Public
    var didPressAt: ((NSPoint) -> Void)?
    var minimumPressDuration: TimeInterval = 1
    
    /// Core
    private var location: NSPoint = .zero
    private var began_time: Date!
    private var timer: Timer?
    
    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
        began_time = Date()
        location = event.allTouches().first?.location(in: self) ?? .zero
        timer = Timer.scheduledTimer(withTimeInterval: minimumPressDuration, repeats: false, block: { [unowned self] _ in
            self.didPressAt?(self.location)
        })
    }
    
    override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
        location = event.allTouches().first?.location(in: self) ?? .zero
    }
    
    override func touchesEnded(with event: NSEvent) {
        timer?.invalidate()
        location = .zero
    }
}

class ControlCenterWidget: PockWidget {
    
    /// Core
    fileprivate let controls: [ControlCenterItem] = [
        CCBrightnessDownItem(),
        CCBrightnessUpItem(),
        CCVolumeDownItem(),
        CCVolumeUpItem()
    ]
    
    /// UI
    fileprivate var segmentedControl: PressableSegmentedControl!
    
    override func customInit() {
        self.customizationLabel = "Control Center"
        self.initializeSegmentedControl()
        self.set(view: segmentedControl)
    }
    
    private func initializeSegmentedControl() {
        let items = controls.map({ $0.icon }) as [NSImage]
        segmentedControl = PressableSegmentedControl(images: items, trackingMode: .momentary, target: self, action: #selector(tap(_:)))
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.autoresizingMask = [.width, .height]
        controls.enumerated().forEach({ index, _ in
            segmentedControl.setWidth(50, forSegment: index)
        })
        segmentedControl.didPressAt = { [unowned self] location in
            self.longTap(at: location)
        }
    }
    
    @objc private func tap(_ sender: NSSegmentedControl) {
        controls[sender.selectedSegment].action()
    }
    
    @objc private func longTap(at location: CGPoint) {
        let index = Int(ceil(location.x / (segmentedControl.frame.width / 4))) - 1
        segmentedControl.selectedSegment = index
        controls[index].longPressAction()
    }
}

extension ControlCenterWidget: NSGestureRecognizerDelegate {
    
}
