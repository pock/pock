//
//  PockSlideableController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 12/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class PockSlideableController: PockTouchBarController {
    
    /// UI Elements
    @IBOutlet private weak var slider:        NSSlider!
    @IBOutlet private weak var leftItemView:  NSButton!
    @IBOutlet private weak var rightItemView: NSButton!
    
    /// Core
    private var down_item: ControlCenterItem? { didSet { leftItemView.image  = down_item?.icon } }
    private var up_item:   ControlCenterItem? { didSet { rightItemView.image = up_item?.icon   } }
    private var location:     NSPoint = .zero
    private var currentValue: CGFloat = 0 {
        didSet {
            slider.doubleValue = Double(currentValue)
        }
    }
    
    deinit {
        if !isProd { print("[PockSlideableController]: Deinit slideable controller") }
    }
    
    override func didLoad() {
        slider.minValue = 0
        slider.maxValue = 100
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // TODO: Update slider to current value
    }
    
    @IBAction private func dismissAction(_ sender: Any) {
        self.dismiss()
    }
    
    @IBAction private func itemAction(_ sender: NSButton) {
        switch sender.identifier?.rawValue {
        case "LeftItemView":
            self.down_item?.action()
        case "RightItemView":
            self.up_item?.action()
        default:
            return
        }
    }
    
    func set(initialLocation location: NSPoint) {
        let distance = self.location.x.distance(to: location.x)
        self.currentValue += distance
        self.location = location
        print(distance)
    }
    
    func set(currentValue: CGFloat) {
        self.currentValue = currentValue
    }
    
    func set(downItem: ControlCenterItem?, upItem: ControlCenterItem?) {
        self.down_item = downItem
        self.up_item   = upItem
    }
    
}
