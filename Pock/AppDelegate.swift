//
//  AppDelegate.swift
//  Pock
//
//  Created by Pierluigi Galdi on 08/09/17.
//  Copyright © 2017 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Preferences
import Fabric
import Crashlytics

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// IBOutlets
    @IBOutlet weak var touchBarController: PockTouchBarController!
    
    /// Status bar Pock icon
    fileprivate let pockStatusbarIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    /// Preferences
    fileprivate let generalPreferencePane: GeneralPreferencePane = GeneralPreferencePane()
    fileprivate var preferencesWindowController: PreferencesWindowController!
    
    /// Finish launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
        /// Initialize Crashlytics only in release modi
        #if PROD
            UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
            Fabric.with([Crashlytics.self])
        #endif
        
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
            menu.addItem(withTitle: "Customize", action: #selector(openCustomization), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit Pock.", action: #selector(NSApp.terminate(_:)), keyEquivalent: "")
            pockStatusbarIcon.menu = menu
        }
        
        /// Check for updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
            self?.checkForUpdates()
        })
        
        /// Present Pock
        self.touchBarController.present()
        
        /// Set Pock inactive
        NSApp.deactivate()
        
    }
    
    /// Will terminate
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    /// Check for updates
    private func checkForUpdates() {
        GeneralPreferencePane.hasLatestVersion(completion: { [weak self] versionNumber, downloadURL in
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
