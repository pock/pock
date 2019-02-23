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
    
    init() {
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
            iconName = NSImage.Name("powerIsCharging")
        }else {
            iconName = NSImage.Name("powerEmpty")
        }
        iconView.image = NSImage(named: iconName)
        // TODO: Keep this here for test purpose only.
        buildBatteryIcon(withValue: powerStatus.currentValue)
    }
    
    private func buildBatteryIcon(withValue value: Int) {
        iconView.subviews.forEach({ $0.removeFromSuperview() })
        let middleImage = NSImageView(image: NSImage(named: NSImage.Name("powerMiddle"))!)
        middleImage.imageScaling = .scaleAxesIndependently
        let width = (iconView.frame.width - ((iconView.frame.width * CGFloat(value)) / 100)) + 2
        iconView.addSubview(middleImage)
        middleImage.snp.makeConstraints({ maker in
            maker.top.equalTo(iconView).inset(2)
            maker.left.equalTo(iconView).inset(2)
            maker.bottom.equalTo(iconView).inset(2)
            maker.right.equalTo(iconView).inset(width)
        })
    }
}
