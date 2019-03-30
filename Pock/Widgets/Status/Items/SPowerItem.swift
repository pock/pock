//
//  SPowerItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import IOKit.ps

struct SPowerStatus {
    var isCharging: Bool, currentValue: Int
}

class SPowerItem: StatusItem {
    
    /// Core
    private var powerStatus: SPowerStatus = SPowerStatus(isCharging: false, currentValue: 0)
    
    /// UI
    private let iconView: NSImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 26, height: 26))
    private let bodyView: NSView      = NSView(frame: NSRect(x: 2, y: 2, width: 21, height: 8))
    
    init() {
        bodyView.layer?.cornerRadius = 1
        reload()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reload), userInfo: nil, repeats: true)
    }
    
    var title: String  { return "power" }
    
    var view: NSView { return iconView }
    
    func action() {
        print("[Pock]: Power Status icon tapped!")
    }
    
    @objc func reload() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: AnyObject]
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int {
                self.powerStatus.currentValue = capacity
            }
            if let isCharging = info[kIOPSIsChargingKey] as? Bool {
                self.powerStatus.isCharging = isCharging
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.updateIcon()
        }
    }
    
    private func updateIcon() {
        var iconName: NSImage.Name!
        if powerStatus.isCharging {
            iconView.subviews.forEach({ $0.removeFromSuperview() })
            iconName = NSImage.Name("powerIsCharging")
        }else {
            iconName = NSImage.Name("powerEmpty")
            buildBatteryIcon(withValue: powerStatus.currentValue)
        }
        iconView.image = NSImage(named: iconName)
    }
    
    private func buildBatteryIcon(withValue value: Int) {
        let width = ((CGFloat(value) / 100) * (iconView.frame.width - 7))
        if !iconView.subviews.contains(bodyView) {
            iconView.addSubview(bodyView)
        }
        bodyView.layer?.backgroundColor = value > 10 ? NSColor.lightGray.cgColor : NSColor.red.cgColor
        bodyView.frame.size.width = max(width, 1.25)
    }
}
