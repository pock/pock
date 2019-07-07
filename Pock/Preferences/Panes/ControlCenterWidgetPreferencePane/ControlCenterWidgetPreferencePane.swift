//
//  ControlCenterWidgetPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Preferences
import Defaults

class ControlCenterWidgetPreferencePane: NSViewController, PreferencePane {

    /// UI
    @IBOutlet weak var showSleepItem:           NSButton!
    @IBOutlet weak var showLockItem:            NSButton!
    @IBOutlet weak var showBrightnessItem:      NSButton!
    @IBOutlet weak var showVolumeItem:          NSButton!
    @IBOutlet weak var showBrightnessDownItem:  NSButton!
    @IBOutlet weak var showBrightnessUpItem:    NSButton!
    @IBOutlet weak var showVolumeDownItem:      NSButton!
    @IBOutlet weak var showVolumeUpItem:        NSButton!
    
    /// Preferenceable
    var preferencePaneIdentifier: Identifier = Identifier.controler_center_widget
    let preferencePaneTitle:      String     = "Control Center Widget".localized
    var toolbarItemIcon:          NSImage    = NSImage(named: "ControlCenterWidget")!
    
    override var nibName: NSNib.Name? {
        return "ControlCenterWidgetPreferencePane"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.superview?.wantsLayer = true
        self.view.wantsLayer = true
        self.loadCheckboxState()
    }
    
    private func loadCheckboxState() {
        self.showSleepItem.state          = defaults[.shouldShowSleepItem]          ? .on : .off
        self.showLockItem.state           = defaults[.shouldShowLockItem]           ? .on : .off
        self.showBrightnessItem.state     = defaults[.shouldShowBrightnessItem]     ? .on : .off
        self.showVolumeItem.state         = defaults[.shouldShowVolumeItem]         ? .on : .off
        self.showBrightnessDownItem.state = defaults[.shouldShowBrightnessDownItem] ? .on : .off
        self.showBrightnessUpItem.state   = defaults[.shouldShowBrightnessUpItem]   ? .on : .off
        self.showVolumeDownItem.state     = defaults[.shouldShowVolumeDownItem]     ? .on : .off
        self.showVolumeUpItem.state       = defaults[.shouldShowVolumeUpItem]       ? .on : .off
        self.showBrightnessDownItem.isEnabled = defaults[.shouldShowBrightnessItem]
        self.showBrightnessUpItem.isEnabled = defaults[.shouldShowBrightnessItem]
        self.showVolumeDownItem.isEnabled = defaults[.shouldShowVolumeItem]
        self.showVolumeUpItem.isEnabled = defaults[.shouldShowVolumeItem]
    }
    
    @IBAction func didChangeCheckboxValue(_ checkbox: NSButton) {
        var key: Defaults.Key<Bool>
        switch checkbox.tag {
        case 1:
            key = .shouldShowSleepItem
        case 2:
            key = .shouldShowLockItem
        case 3:
            key = .shouldShowBrightnessItem
        case 31:
            key = .shouldShowBrightnessDownItem
        case 32:
            key = .shouldShowBrightnessUpItem
        case 4:
            key = .shouldShowVolumeItem
        case 41:
            key = .shouldShowVolumeDownItem
        case 42:
            key = .shouldShowVolumeUpItem
        default:
            return
        }
        defaults[key] = checkbox.state == .on
        loadCheckboxState()
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadControlCenterWidget, object: nil)
    }
    
}
