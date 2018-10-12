//
//  GeneralPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 12/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Preferences
import Defaults

final class GeneralPreferencePane: NSViewController, Preferenceable {
    
    /// UI
    @IBOutlet weak var notificationBadgeRefreshRatePicker: NSPopUpButton!
    @IBOutlet weak var launchAtLoginCheckbox:              NSButton!
    
    /// Preferenceable
    let toolbarItemTitle: String   = "General"
    let toolbarItemIcon:  NSImage? = nil
    
    /// Data
    private let notificationBadgeRefreshRateOptions: [NotificationBadgeRefreshRateKeys] = [
        NotificationBadgeRefreshRateKeys.instantly,
        NotificationBadgeRefreshRateKeys.fiveSeconds,
        NotificationBadgeRefreshRateKeys.tenSeconds,
        NotificationBadgeRefreshRateKeys.thirtySeconds,
        NotificationBadgeRefreshRateKeys.oneMinute,
        NotificationBadgeRefreshRateKeys.threeMinutes
    ]
    
    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "GeneralPreferencePane")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.populatePopUpButton()
    }
    
    private func populatePopUpButton() {
        self.notificationBadgeRefreshRatePicker.removeAllItems()
        self.notificationBadgeRefreshRatePicker.addItems(withTitles: notificationBadgeRefreshRateOptions.map({ $0.toString() }))
        self.notificationBadgeRefreshRatePicker.selectItem(withTitle: defaults[.notificationBadgeRefreshInterval].toString())
    }
    
    @IBAction private func didSelectNotificationBadgeRefreshRate(_: NSButton) {
        defaults[.notificationBadgeRefreshInterval] = notificationBadgeRefreshRateOptions[self.notificationBadgeRefreshRatePicker.indexOfSelectedItem]
        NSWorkspace.shared.notificationCenter.post(name: .didChangeNotificationBadgeRefreshRate, object: nil)
    }
}
