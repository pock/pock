//
//  SPowerItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults
import IOKit.ps

struct SPowerStatus {
    var isCharging: Bool, currentValue: Int
}

class SPowerItem: StatusItem {
    
    /// Core
    private var refreshTimer: Timer?
    private var powerStatus: SPowerStatus = SPowerStatus(isCharging: false, currentValue: 0)
    private var shouldShowBatteryIcon: Bool {
        return Defaults[.shouldShowBatteryIcon]
    }
    private var shouldShowBatteryPercentage: Bool {
        return Defaults[.shouldShowBatteryPercentage]
    }
    
    /// UI
    private let stackView: NSStackView = NSStackView(frame: .zero)
    private let iconView: NSImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 26, height: 26))
    private let bodyView: NSView      = NSView(frame: NSRect(x: 2, y: 2, width: 21, height: 8))
    private let valueLabel: NSTextField = NSTextField(frame: .zero)
    
    init() {
        didLoad()
        reload()
    }
    
    deinit {
        didUnload()
    }
    
    func didLoad() {
        bodyView.layer?.cornerRadius = 1
        configureValueLabel()
        configureStackView()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.reload()
        })
    }
    
    func didUnload() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    var enabled: Bool{ return Defaults[.shouldShowPowerItem] }
    
    var title: String  { return "power" }
    
    var view: NSView { return stackView }
    
    func action() {
        if !isProd { print("[Pock]: Power Status icon tapped!") }
    }
    
    private func configureValueLabel() {
        valueLabel.font = NSFont.systemFont(ofSize: 13)
        valueLabel.backgroundColor = .clear
        valueLabel.isBezeled = false
        valueLabel.isEditable = false
        valueLabel.sizeToFit()
    }
    
    private func configureStackView() {
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .fillProportionally
        stackView.spacing = 2
        stackView.addArrangedSubview(valueLabel)
        stackView.addArrangedSubview(iconView)
    }
    
    func reload() {
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
            self?.updateIcon(value: self?.powerStatus.currentValue ?? 0)
        }
    }
    
    private func updateIcon(value: Int) {
        if shouldShowBatteryIcon {
            var iconName: NSImage.Name!
            if powerStatus.isCharging {
                iconView.subviews.forEach({ $0.removeFromSuperview() })
                iconName = "powerIsCharging"
            }else {
                iconName = "powerEmpty"
                buildBatteryIcon(withValue: value)
            }
            iconView.image    = NSImage(named: iconName)
            iconView.isHidden = false
        }else {
            iconView.isHidden = true
            iconView.image    = nil
            iconView.subviews.forEach({ $0.removeFromSuperview() })
        }
        valueLabel.stringValue = shouldShowBatteryPercentage ? "\(value)%" : ""
        valueLabel.isHidden    = !shouldShowBatteryPercentage
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
