//
//  DockWidgetPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Preferences
import Defaults

class DockWidgetPreferencePane: NSViewController, PreferencePane {
    
    @IBOutlet weak var notificationBadgeRefreshRatePicker: NSPopUpButton!
    @IBOutlet weak var hideFinderCheckbox:                 NSButton!
    @IBOutlet weak var showOnlyRunningApps:                NSButton!
    @IBOutlet weak var hideTrashCheckbox:                  NSButton!
    @IBOutlet weak var hidePersistentItemsCheckbox:        NSButton!
    
    /// Preferenceable
    var preferencePaneIdentifier: Identifier = Identifier.dock_widget
    let preferencePaneTitle:      String     = "Dock Widget"
    let toolbarItemIcon: NSImage = NSWorkspace.shared.icon(forFile: NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: "com.apple.dock") ?? "")
    
    override var nibName: NSNib.Name? {
        return "DockWidgetPreferencePane"
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.populatePopUpButton()
        self.setupCheckboxes()
    }
    
    private func populatePopUpButton() {
        self.notificationBadgeRefreshRatePicker.removeAllItems()
        self.notificationBadgeRefreshRatePicker.addItems(withTitles: NotificationBadgeRefreshRateKeys.allCases.map({ $0.toString() }))
        self.notificationBadgeRefreshRatePicker.selectItem(withTitle: defaults[.notificationBadgeRefreshInterval].toString())
    }
    
    private func setupCheckboxes() {
        self.hideFinderCheckbox.state           = defaults[.hideFinder]          ? .on : .off
        self.showOnlyRunningApps.state          = defaults[.showOnlyRunningApps] ? .on : .off
        self.hideTrashCheckbox.state            = defaults[.hideTrash]           ? .on : .off
        self.hidePersistentItemsCheckbox.state  = defaults[.hidePersistentItems] ? .on : .off
        self.hideTrashCheckbox.isEnabled        = !defaults[.hidePersistentItems]
    }
    
    @IBAction private func didSelectNotificationBadgeRefreshRate(_: NSButton) {
        defaults[.notificationBadgeRefreshInterval] = NotificationBadgeRefreshRateKeys.allCases[self.notificationBadgeRefreshRatePicker.indexOfSelectedItem]
        NSWorkspace.shared.notificationCenter.post(name: .didChangeNotificationBadgeRefreshRate, object: nil)
    }
    
    @IBAction private func didChangeHideFinderValue(button: NSButton) {
        defaults[.hideFinder] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadDock, object: nil)
    }
    
    @IBAction private func didChangeShowOnlyRunningAppsValue(button: NSButton) {
        defaults[.showOnlyRunningApps] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadDock, object: nil)
    }
    
    @IBAction private func didChangeHideTrashValue(button: NSButton) {
        defaults[.hideTrash] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPersistentItems, object: nil)
    }
    
    @IBAction private func didChangeHidePersistentValue(button: NSButton) {
        defaults[.hidePersistentItems] = button.state == .on
        hideTrashCheckbox.isEnabled = !defaults[.hidePersistentItems]
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPersistentItems, object: nil)
    }
    
}
