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
    @IBOutlet weak var launchAtLoginCheckbox:              NSButton!
    @IBOutlet weak var checkForUpdatesButton:              NSButton!
    
    /// Core
    private static let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    /// Preferenceable
    let toolbarItemTitle: String   = "General"
    let toolbarItemIcon:  NSImage  = NSImage(named: NSImage.Name("pock-icon"))!
    
    /// Updates
    var newVersionAvailable: (String, URL)?
    
    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "GeneralPreferencePane")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadVersionNumber()
        self.populatePopUpButton()
        self.setupHideControlStripCheckbox()
        self.setupLaunchAtLoginCheckbox()
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
    
    private func setupLaunchAtLoginCheckbox() {
        self.launchAtLoginCheckbox.state = LaunchAtLogin.isEnabled ? .on : .off
    }
    
    private func setupHideControlStripCheckbox() {
        self.hideControlStripCheckbox.state = defaults[.hideControlStrip] ? .on : .off
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
    
    @IBAction private func checkForUpdates(_: NSButton) {
        
        self.checkForUpdatesButton.isEnabled = false
        self.checkForUpdatesButton.title     = "Checking..."
        
        GeneralPreferencePane.hasLatestVersion(completion: { [weak self] latestVersion, latestVersionDownloadURL in
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
    
}

extension GeneralPreferencePane {
    #if DEBUG
    static let latestVersionURLString: String = "http://pock.pigigaldi.com/api/dev/latestRelease.json"
    #else
    static let latestVersionURLString: String = "http://pock.pigigaldi.com/api/latestRelease.json"
    #endif
    
    class func hasLatestVersion(completion: @escaping (String?, URL?) -> Void) {
        let latestVersionURL: URL = URL(string: latestVersionURLString)!
        URLSession.shared.dataTask(with: latestVersionURL, completionHandler: { data, response, error in
            guard let json                = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: String],
                  let latestVersionNumber = json?["version_number"], GeneralPreferencePane.appVersion < latestVersionNumber,
                  let downloadLink        = json?["download_link"],
                  let downloadURL         = URL(string: downloadLink) else {
                    completion(nil, nil)
                    return
            }
            completion(latestVersionNumber, downloadURL)
        }).resume()
    }
    
}
