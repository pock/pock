//
//  PockSlideableController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 12/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class PKSlideableController: PKTouchBarController {
    
    /// UI Elements
    @IBOutlet         weak var slider:        NSSlider!
    @IBOutlet private weak var leftItemView:  NSButton!
    @IBOutlet private weak var rightItemView: NSButton!
    
    /// Core
    private var down_item: ControlCenterItem? { didSet { leftItemView.image  = down_item?.icon } }
    private var up_item:   ControlCenterItem? { didSet { rightItemView.image = up_item?.icon   } }
    private var location:     NSPoint = .zero
    private var currentValue: Float {
        get {
            return Float(slider?.doubleValue ?? 0)
        }
        set {
            slider?.doubleValue = Double(newValue)
        }
    }
    
    deinit {
        if !isProd { print("[PockSlideableController]: Deinit slideable controller") }
    }
    
    override func didLoad() {
        slider.minValue = 0
        slider.maxValue = 1
        slider.isContinuous = true
        slider.target       = self
        slider.action       = #selector(didChangeSliderValue(_:))
    }
    
    @IBAction private func dismissAction(_ sender: Any) {
        navigationController?.popLastController()
    }
    
    @IBAction private func itemAction(_ sender: NSButton) {
        switch sender.identifier?.rawValue {
        case "LeftItemView":
            if let newValue = self.down_item?.action() as? Float {
                currentValue = newValue
            }
        case "RightItemView":
            if let newValue = self.up_item?.action() as? Float {
                currentValue = newValue
            }
        default:
            return
        }
    }
    
    @objc private func didChangeSliderValue(_ sender: NSSlider) {
        if let upItem = up_item {
            upItem.didSlide(at: sender.doubleValue)
            return
        }
        if let downItem = down_item {
            downItem.didSlide(at: sender.doubleValue)
        }
    }
    
    func set(initialLocation location: NSPoint) {
        /* WIP */
        /* let distance = self.location.x.distance(to: location.x)
        self.location = location
        print(distance) */
    }
    
    func set(currentValue: Float) {
        self.currentValue = currentValue
    }
    
    func set(downItem: ControlCenterItem?, upItem: ControlCenterItem?) {
        self.down_item = downItem
        self.up_item   = upItem
    }
    
}
