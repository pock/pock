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
    fileprivate let statusWidgetPreferencePane: StatusWidgetPreferencePane = StatusWidgetPreferencePane()
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
        self.preferencesWindowController = PreferencesWindowController(viewControllers: [generalPreferencePane, statusWidgetPreferencePane])
        
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
        
        /// Present Pock
        self.touchBarController.present()
        
        /// Set Pock inactive
        NSApp.deactivate()
        
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
    
    @objc private func openCustomization() {
        touchBarController.openCustomization()
    }
    
}
