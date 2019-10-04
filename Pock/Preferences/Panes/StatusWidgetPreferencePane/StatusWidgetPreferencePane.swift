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

class StatusWidgetPreferencePane: NSViewController, PreferencePane {

    /// UI
    @IBOutlet weak var showWifiItem:                NSButton!
    @IBOutlet weak var showPowerItem:               NSButton!
    @IBOutlet weak var showBatteryIconItem:         NSButton!
    @IBOutlet weak var showBatteryPercentageItem:   NSButton!
    @IBOutlet weak var showDateItem:                NSButton!
    @IBOutlet weak var show24TimeItem:              NSButton!
    @IBOutlet weak var showWeather:                 NSButton!
    @IBOutlet weak var useCelcius:                  NSButton!
    
    // @IBOutlet weak var showSpotlightItem:           NSButton!
    
    /// Preferenceable
    var preferencePaneIdentifier: Identifier = Identifier.status_widget
    let preferencePaneTitle:      String     = "Status Widget".localized
    var toolbarItemIcon:          NSImage {
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: "com.apple.systempreferences")!
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    override var nibName: NSNib.Name? {
        return "StatusWidgetPreferencePane"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.superview?.wantsLayer = true
        self.view.wantsLayer = true
        self.loadCheckboxState()
    }
    
    private func loadCheckboxState() {
        self.showWifiItem.state              = Defaults[.shouldShowWifiItem]          ? .on : .off
        self.showPowerItem.state             = Defaults[.shouldShowPowerItem]         ? .on : .off
        self.showBatteryIconItem.state       = Defaults[.shouldShowBatteryIcon]       ? .on : .off
        self.showBatteryPercentageItem.state = Defaults[.shouldShowBatteryPercentage] ? .on : .off
        self.showDateItem.state              = Defaults[.shouldShowDateItem]          ? .on : .off
        self.show24TimeItem.state            = Defaults[.shouldShow24TimeItem]        ? .on : .off
        self.showWeather.state               = Defaults[.showWeatherItem]
            ? .on : .off
        self.useCelcius.state                = Defaults[.weatherUseCelcius]
            ? .on : .off
        // self.showSpotlightItem.state         = defaults[.shouldShowSpotlightItem]     ? .on : .off
    }
    
    @IBAction func didChangeCheckboxValue(_ checkbox: NSButton) {
        var key: Defaults.Key<Bool>
        switch checkbox.tag {
        case 1:
            key = .shouldShowWifiItem
        case 2:
            key = .shouldShowPowerItem
        case 21:
            key = .shouldShowBatteryIcon
        case 22:
            key = .shouldShowBatteryPercentage
        case 3:
            key = .shouldShowDateItem
        case 31:
            key = .shouldShow24TimeItem
        case 45:
            key = .showWeatherItem
        case 46:
            key = .weatherUseCelcius
        /* case 4:
            key = .shouldShowSpotlightItem */
        default:
            return
        }
        Defaults[key] = checkbox.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadStatusWidget, object: nil)
    }
    
}
