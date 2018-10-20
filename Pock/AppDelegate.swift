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

@available(OSX 10.12.2, *)
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// Status bar Pock icon
    fileprivate let pockStatusbarIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    /// Preferences
    fileprivate let preferencesWindowController: PreferencesWindowController = PreferencesWindowController(viewControllers: [GeneralPreferencePane()])
    
    /// Finish launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        /// Initialize Crashlytics
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])
        
        /// Check for accessibility (needed for badges to work)
        self.checkAccessibility()
        
        /// Check for status bar icon
        if let button = pockStatusbarIcon.button {
            button.image = #imageLiteral(resourceName: "pock-inner-icon")
            button.image?.isTemplate = true
            /// Create menu
            let menu = NSMenu(title: "Menu")
            menu.addItem(withTitle: "Preferences", action: #selector(openPreferences), keyEquivalent: "P")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit Pock.", action: #selector(NSApp.terminate(_:)), keyEquivalent: "")
            pockStatusbarIcon.menu = menu
        }
        
        /// Set Pock inactive
        NSApp.deactivate()
        
        /// Load Pock
        PockController.shared.loadPock()
        
    }
    
    /// Will terminate
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
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
    
}
