//
//  StatusWidgetPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 30/03/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Preferences
import Defaults

class StatusWidgetPreferencePane: NSViewController, Preferenceable {

    /// UI
    @IBOutlet weak var showWifiItem:      NSButton!
    @IBOutlet weak var showPowerItem:     NSButton!
    @IBOutlet weak var showDateItem:      NSButton!
    @IBOutlet weak var showSpotlightItem: NSButton!
    
    /// Preferenceable
    let toolbarItemTitle: String   = "Status"
    let toolbarItemIcon:  NSImage  = NSImage(named: NSImage.Name.advanced)!
    
    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "StatusWidgetPreferencePane")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadCheckboxState()
    }
    
    private func loadCheckboxState() {
        self.showWifiItem.state      = defaults[.shouldShowWifiItem]      ? .on : .off
        self.showPowerItem.state     = defaults[.shouldShowPowerItem]     ? .on : .off
        self.showDateItem.state      = defaults[.shouldShowDateItem]      ? .on : .off
        self.showSpotlightItem.state = defaults[.shouldShowSpotlightItem] ? .on : .off
    }
    
    @IBAction func didChangeCheckboxValue(_ checkbox: NSButton) {
        var key: Defaults.Key<Bool>? = nil
        switch checkbox.tag {
        case 0:
            key = .shouldShowWifiItem
        case 1:
            key = .shouldShowPowerItem
        case 2:
            key = .shouldShowDateItem
        case 3:
            key = .shouldShowSpotlightItem
        default:
            return
        }
        guard let k = key else { return }
        defaults[k] = checkbox.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadStatusWidget, object: nil)
    }
    
}
