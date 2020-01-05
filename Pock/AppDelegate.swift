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
import Magnet
@_exported import PockKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static var `default`: AppDelegate {
        return NSApp.delegate as! AppDelegate
    }
    
    /// Core
    public private(set) var alertWindow:   AlertWindowController?
    public private(set) var navController: PKTouchBarNavController?
    
    /// Timer
    fileprivate var automaticUpdatesTimer: Timer?
    
    /// Status bar Pock icon
    fileprivate let pockStatusbarIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    /// Main Pock menu
    private lazy var mainPockMenu: NSMenu = {
        let menu = NSMenu(title: "Pock Options")
        menu.addItem(withTitle: "Preferences…".localized, action: #selector(openPreferences), keyEquivalent: ",")
        menu.addItem(withTitle: "Customize…".localized, action: #selector(openCustomization), keyEquivalent: "c")
        menu.addItem(NSMenuItem.separator())
        let advancedMenuItem = NSMenuItem(title: "Advanced".localized, action: nil, keyEquivalent: "")
        advancedMenuItem.submenu = advancedPockMenu
        menu.addItem(advancedMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Support this project".localized, action: #selector(openDonateURL),  keyEquivalent: "s")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Pock".localized, action: #selector(NSApp.terminate), keyEquivalent: "q")
        return menu
    }()
    
    private lazy var advancedPockMenu: NSMenu = {
        let menu = NSMenu(title: "Advanced".localized)
        menu.addItem(withTitle: "Reload Pock".localized, action: #selector(reloadPock), keyEquivalent: "r")
        menu.addItem(withTitle: "Reload System Touch Bar".localized, action: #selector(reloadTouchBarServer), keyEquivalent: "a")
        return menu
    }()
    
    /// Preferences
    fileprivate let generalPreferencePane: GeneralPreferencePane = GeneralPreferencePane()
    fileprivate let dockWidgetPreferencePane: DockWidgetPreferencePane = DockWidgetPreferencePane()
    fileprivate let statusWidgetPreferencePane: StatusWidgetPreferencePane = StatusWidgetPreferencePane()
    fileprivate let controlCenterWidgetPreferencePane: ControlCenterWidgetPreferencePane = ControlCenterWidgetPreferencePane()
    fileprivate let nowPlayingWidgetPreferencePane: NowPlayingPreferencePane = NowPlayingPreferencePane()
    fileprivate var preferencesWindowController: PreferencesWindowController!
    
    /// Finish launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        /// Initialize Crashlytics
        if isProd {
            UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
            Fabric.with([Crashlytics.self])
        }
        
        /// Check for legacy hideControlStrip option
        if let shouldHideControlStrip = Defaults[.hideControlStrip] {
            if shouldHideControlStrip && TouchBarHelper.isSystemControlStripVisible {
                alertWindow = AlertWindowController(
                    title:   "Hide Control Strip".localized,
                    message: "Hide_Control_Strip_Message".localized,
                    action: AlertAction(
                        title: "Continue".localized,
                        action: {
                            TouchBarHelper.hideSystemControlStrip({ [weak self] success in
                                if success {
                                    Defaults[.hideControlStrip] = nil
                                }
                                self?.initialize()
                                self?.alertWindow = nil
                            })
                        }
                    )
                )
                alertWindow?.showWindow(self)
            }
        }else {
            self.initialize()
        }
        
        /// Set Pock inactive
        NSApp.deactivate()

    }
    
    private func initialize() {
        /// Check for accessibility (needed for badges to work)
        self.checkAccessibility()
        
        /// Preferences
        self.preferencesWindowController = PreferencesWindowController(preferencePanes: [
            generalPreferencePane,
            dockWidgetPreferencePane,
            statusWidgetPreferencePane,
            controlCenterWidgetPreferencePane,
            nowPlayingWidgetPreferencePane
        ])
        
        /// Check for status bar icon
        if let button = pockStatusbarIcon.button {
            button.image = NSImage(named: "pock-inner-icon")
            button.image?.isTemplate = true
            /// Create menu
            pockStatusbarIcon.menu = mainPockMenu
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
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reloadPock),
                                                          name: .shouldReloadPock,
                                                          object: nil)
        toggleAutomaticUpdatesTimer()
        registerGlobalHotKey()
        
        /// Present Pock
        self.reloadPock()
    }
    
    @objc func reloadPock() {
        navController?.dismiss()
        navController = nil
        let mainController: PockMainController = PockMainController.load()
        navController = PKTouchBarNavController(rootController: mainController)
    }
    
    @objc func reloadTouchBarServer() {
        TouchBarHelper.reloadTouchBarServer { [weak self] success in
            if success {
                self?.reloadPock()
            }
        }
    }
    
    private func registerGlobalHotKey() {
        if let keyCombo = KeyCombo(doubledCocoaModifiers: .control) {
            let hotKey = HotKey(identifier: "TogglePock", keyCombo: keyCombo) { [weak self] _ in
                self?.navController?.toggle()
            }
            hotKey.register()
        }
    }
    
    @objc private func toggleAutomaticUpdatesTimer() {
        if Defaults[.enableAutomaticUpdates] {
            automaticUpdatesTimer = Timer.scheduledTimer(timeInterval: 86400 /*24h*/, target: self, selector: #selector(checkForUpdates), userInfo: nil, repeats: true)
        }else {
            automaticUpdatesTimer?.invalidate()
            automaticUpdatesTimer = nil
        }
    }
    
    /// Will terminate
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        NotificationCenter.default.removeObserver(self)
        navController?.dismiss()
        navController = nil
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
        preferencesWindowController.show()
    }
    
    @objc private func openCustomization() {
        (navController?.rootController as? PockMainController)?.openCustomization()
    }
    
    @objc private func openDonateURL() {
        guard let url = URL(string: "https://paypal.me/pigigaldi") else { return }
        NSWorkspace.shared.open(url)
    }
    
}
