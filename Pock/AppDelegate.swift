//
//  AppDelegate.swift
//  Pock
//
//  Created by Pierluigi Galdi on 08/09/17.
//  Copyright © 2017 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Defaults
import Preferences
import Fabric
import Crashlytics

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// IBOutlets
    @IBOutlet weak var touchBarController: PockTouchBarController!
    
    /// Timer
    fileprivate var automaticUpdatesTimer: Timer?
    
    /// Status bar Pock icon
    fileprivate let pockStatusbarIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    /// Preferences
    fileprivate let generalPreferencePane: GeneralPreferencePane = GeneralPreferencePane()
    fileprivate var preferencesWindowController: PreferencesWindowController!
    
    /// Finish launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
        /// Initialize Crashlytics
        if isProd {
            UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
            Fabric.with([Crashlytics.self])
        }
        
        /// Check for accessibility (needed for badges to work)
        self.checkAccessibility()
        
        /// Preferences
        self.preferencesWindowController = PreferencesWindowController(viewControllers: [generalPreferencePane])
        
        /// Check for status bar icon
        if let button = pockStatusbarIcon.button {
            button.image = #imageLiteral(resourceName: "pock-inner-icon")
            button.image?.isTemplate = true
            /// Create menu
            let menu = NSMenu(title: "Menu")
            menu.addItem(withTitle: "Preferences", action: #selector(openPreferences), keyEquivalent: "")
            // menu.addItem(withTitle: "Customize", action: #selector(openCustomization), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit Pock.", action: #selector(NSApp.terminate(_:)), keyEquivalent: "")
            pockStatusbarIcon.menu = menu
        }
        
        /// Check for updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
            self?.checkForUpdates()
        })
        
        /// Register for notification
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(toggleAutomaticUpdatesTimer),
                                                          name: .shouldEnableAutomaticUpdates,
                                                          object: nil)
        toggleAutomaticUpdatesTimer()
        
        /// Present Pock
        self.touchBarController.present()
        
        /// Set Pock inactive
        NSApp.deactivate()
        
    }
    
    @objc private func toggleAutomaticUpdatesTimer() {
        if defaults[.enableAutomaticUpdates] {
            automaticUpdatesTimer = Timer.scheduledTimer(timeInterval: 86400 /*24h*/, target: self, selector: #selector(checkForUpdates), userInfo: nil, repeats: true)
        }else {
            automaticUpdatesTimer?.invalidate()
            automaticUpdatesTimer = nil
        }
    }
    
    /// Will terminate
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    /// Check for updates
    @objc private func checkForUpdates() {
        generalPreferencePane.hasLatestVersion(completion: { [weak self] versionNumber, downloadURL in
            guard let versionNumber = versionNumber, let downloadURL = downloadURL else { return }
            self?.generalPreferencePane.newVersionAvailable = (versionNumber, downloadURL)
            DispatchQueue.main.async { [weak self] in
                self?.openPreferences()
            }
        })
    }
    
    /// Check for accessibility
    @discardableResult
    private func checkAccessibility() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        return accessEnabled
    }
    
    /// Open preferences
    @objc private func openPreferences() {
        preferencesWindowController.showWindow()
    }
    
    @objc private func openCustomization() {
        touchBarController.openCustomization()
    }
    
}
