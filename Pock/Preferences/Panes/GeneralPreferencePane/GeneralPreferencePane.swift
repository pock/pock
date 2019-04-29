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
import LaunchAtLogin

final class GeneralPreferencePane: NSViewController, Preferenceable {
    
    /// UI
    @IBOutlet weak var versionLabel:                       NSTextField!
    @IBOutlet weak var notificationBadgeRefreshRatePicker: NSPopUpButton!
    @IBOutlet weak var hideControlStripCheckbox:           NSButton!
    @IBOutlet weak var hideFinderCheckbox:                 NSButton!
    @IBOutlet weak var hideTrashCheckbox:                  NSButton!
    @IBOutlet weak var hidePersistentItemsCheckbox:        NSButton!
    @IBOutlet weak var launchAtLoginCheckbox:              NSButton!
    @IBOutlet weak var enableAutomaticUpdates:             NSButton!
    @IBOutlet weak var checkForUpdatesButton:              NSButton!
    
    /// Endpoint
    #if DEBUG
    private let latestVersionURLString: String = "https://pock.pigigaldi.com/api/dev/latestRelease.json"
    #else
    private let latestVersionURLString: String = "https://pock.pigigaldi.com/api/latestRelease.json"
    #endif
    
    /// Updates
    var newVersionAvailable: (String, URL)?
    
    /// Core
    private static let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    /// Preferenceable
    let toolbarItemTitle: String   = "General"
    let toolbarItemIcon:  NSImage  = NSImage(named: NSImage.Name("pock-icon"))!
    
    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "GeneralPreferencePane")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadVersionNumber()
        self.populatePopUpButton()
        self.setupCheckboxes()
        if let newVersionNumber = self.newVersionAvailable?.0, let newVersionDownloadURL = self.newVersionAvailable?.1 {
            self.showNewVersionAlert(versionNumber: newVersionNumber, downloadURL: newVersionDownloadURL)
            self.newVersionAvailable = nil
        }
    }
    
    private func loadVersionNumber() {
        self.versionLabel.stringValue = GeneralPreferencePane.appVersion
    }
    
    private func populatePopUpButton() {
        self.notificationBadgeRefreshRatePicker.removeAllItems()
        self.notificationBadgeRefreshRatePicker.addItems(withTitles: NotificationBadgeRefreshRateKeys.allCases.map({ $0.toString() }))
        self.notificationBadgeRefreshRatePicker.selectItem(withTitle: defaults[.notificationBadgeRefreshInterval].toString())
    }
    
    private func setupCheckboxes() {
        self.launchAtLoginCheckbox.state        = LaunchAtLogin.isEnabled        ? .on : .off
        self.hideControlStripCheckbox.state     = defaults[.hideControlStrip]    ? .on : .off
        self.hideFinderCheckbox.state           = defaults[.hideFinder]          ? .on : .off
        self.hideTrashCheckbox.state            = defaults[.hideTrash]           ? .on : .off
        self.hidePersistentItemsCheckbox.state  = defaults[.hidePersistentItems] ? .on : .off
        self.hideTrashCheckbox.isEnabled        = !defaults[.hidePersistentItems]
        self.enableAutomaticUpdates.state       = defaults[.enableAutomaticUpdates] ? .on : .off
    }
    
    @IBAction private func didSelectNotificationBadgeRefreshRate(_: NSButton) {
        defaults[.notificationBadgeRefreshInterval] = NotificationBadgeRefreshRateKeys.allCases[self.notificationBadgeRefreshRatePicker.indexOfSelectedItem]
        NSWorkspace.shared.notificationCenter.post(name: .didChangeNotificationBadgeRefreshRate, object: nil)
    }
    
    @IBAction private func didChangeLaunchAtLoginValue(button: NSButton) {
        LaunchAtLogin.isEnabled = button.state == .on
    }
    
    @IBAction private func didChangeHideControlStripValue(button: NSButton) {
        defaults[.hideControlStrip] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPock, object: nil)
    }
    
    @IBAction private func didChangeHideFinderValue(button: NSButton) {
        defaults[.hideFinder] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadDock, object: nil)
    }
    
    @IBAction private func didChangeHideTrashValue(button: NSButton) {
        defaults[.hideTrash] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadDock, object: nil)
    }
    
    @IBAction private func didChangeHidePersistentValue(button: NSButton) {
        defaults[.hidePersistentItems] = button.state == .on
        hideTrashCheckbox.isEnabled = !defaults[.hidePersistentItems]
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPersistentItems, object: nil)
    }
    
    @IBAction private func didChangeEnableAutomaticUpdates(button: NSButton) {
        defaults[.enableAutomaticUpdates] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldEnableAutomaticUpdates, object: nil)
    }
    
    @IBAction private func checkForUpdates(_ sender: NSButton) {
        self.checkForUpdatesButton.isEnabled = false
        self.checkForUpdatesButton.title     = "Checking..."
        
        self.hasLatestVersion(completion: { [weak self] latestVersion, latestVersionDownloadURL in
            if let latestVersion = latestVersion, let latestVersionDownloadURL = latestVersionDownloadURL {
                self?.showNewVersionAlert(versionNumber: latestVersion, downloadURL: latestVersionDownloadURL)
            }else {
                self?.showAlert(title: "Installed version: \(GeneralPreferencePane.appVersion)", message: "Already on latest version")
            }
            DispatchQueue.main.async { [weak self] in
                self?.checkForUpdatesButton.isEnabled = true
                self?.checkForUpdatesButton.title     = "Check for updates"
            }
        })
    }
}

extension GeneralPreferencePane {
    func showNewVersionAlert(versionNumber: String, downloadURL: URL) {
        self.showAlert(title:      "New version available!",
                       message:    "Do you want to download version \"\(versionNumber)\" now?",
            buttons:    ["Download", "Later"],
            completion: { modalResponse in if modalResponse == .alertFirstButtonReturn { NSWorkspace.shared.open(downloadURL) }
        })
    }
    
    private func showAlert(title: String, message: String, buttons: [String] = [], completion: ((NSApplication.ModalResponse) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let _self = self else { return }
            let alert             = NSAlert()
            alert.alertStyle      = NSAlert.Style.informational
            alert.messageText     = title
            alert.informativeText = message
            for buttonTitle in buttons {
                alert.addButton(withTitle: buttonTitle)
            }
            alert.beginSheetModal(for: _self.view.window!, completionHandler: completion)
        }
    }
    
    struct APIUpdateResponse: Codable {
        let version_number: String
        let download_link:  String
    }
    
    func hasLatestVersion(completion: @escaping (String?, URL?) -> Void) {
        let latestVersionURL: URL = URL(string: latestVersionURLString)!
        let request = URLRequest(url: latestVersionURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        URLSession.shared.invalidateAndCancel()
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let data  = data,
            let apiResponse = try? JSONDecoder().decode(APIUpdateResponse.self, from: data),
            let downloadURL = URL(string: apiResponse.download_link),
            GeneralPreferencePane.appVersion < apiResponse.version_number else {
                NSLog("[Pock]: Already on latest version: \(GeneralPreferencePane.appVersion)")
                completion(nil, nil)
                return
            }
            NSLog("[Pock]: New version available: \(apiResponse.version_number)")
            completion(apiResponse.version_number, downloadURL)
        }).resume()
    }
}

