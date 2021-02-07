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
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import Magnet
@_exported import PockKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static var `default`: AppDelegate {
        return NSApp.delegate as! AppDelegate
    }
    
    /// Core
    public private(set) var alertWindowController: AlertWindowController?
    public private(set) var navController:         PKTouchBarNavigationController?
	public private(set) var screenIsLocked: Bool = false
	
    /// Timer
    fileprivate var automaticUpdatesTimer: Timer?
    
    /// Status bar Pock icon
    fileprivate let pockStatusbarIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    /// Main Pock menu
	@IBOutlet private weak var mainMenu: NSMenu!
	/// Main menu items
	@IBOutlet private weak var aboutPockMenuItem: NSMenuItem!
	@IBOutlet private weak var openPreferencesMenuItem: NSMenuBadgeItem!
	@IBOutlet private weak var openWidgetsManagerMenuItem: NSMenuBadgeItem!
	@IBOutlet private weak var customizeTouchBarMenuItem: NSMenuItem!
	@IBOutlet private weak var installWidgetMenuItem: NSMenuItem!
	@IBOutlet private weak var advancedMenuItem: NSMenuItem!
	@IBOutlet private weak var supportThisProjectMenuItem: NSMenuItem!
	@IBOutlet private weak var quitPockMenuItem: NSMenuItem!
	/// Advanced submeu
	@IBOutlet private weak var reInstallDefaultWidgetsMenuItem: NSMenuItem!
	@IBOutlet private weak var showOnBoardScreenMenuItem: NSMenuItem!
	@IBOutlet private weak var reloadPockMenuItem: NSMenuItem!
	@IBOutlet private weak var relaunchPockMenuItem: NSMenuItem! // alternate: true
	@IBOutlet private weak var relaunchTouchBarAgentMenuItem: NSMenuItem!
	@IBOutlet private weak var relaunchTouchBarServerMenuItem: NSMenuItem! // alternate: true
	
	// MARK: Setup Main Menu Items
	private func setupMainMenuItems() {
		/// Set target
		mainMenu.items.forEach({ $0.target = self })
		/// Set title and actions
		
		// MARK: About Pock
		aboutPockMenuItem.title  = "About Pock".localized
		aboutPockMenuItem.action = #selector(openWebsite)
		aboutPockMenuItem.view	 = NSMenuItemCustomView(item: aboutPockMenuItem)
		// MARK: Open Preferences
		openPreferencesMenuItem.title  = "Open Preferences…".localized
		openPreferencesMenuItem.action = #selector(openPreferences)
		openPreferencesMenuItem.view   = NSMenuBadgeItemView(item: openPreferencesMenuItem)
		// MARK: Open Widgets Manager
		openWidgetsManagerMenuItem.title  = "Open Widgets Manager…".localized
		openWidgetsManagerMenuItem.action = #selector(openWidgetsManager)
		openWidgetsManagerMenuItem.view   = NSMenuBadgeItemView(item: openWidgetsManagerMenuItem)
		// MARK: Customize Touch Bar
		customizeTouchBarMenuItem.title  = "Customize Touch Bar…".localized
		customizeTouchBarMenuItem.action = #selector(openCustomization)
		customizeTouchBarMenuItem.view	 = NSMenuItemCustomView(item: customizeTouchBarMenuItem)
		// MARK: Install (widget)
		installWidgetMenuItem.title  = "Install Widget…".localized
		installWidgetMenuItem.action = #selector(openInstallWidgetsManager)
		installWidgetMenuItem.view	 = NSMenuItemCustomView(item: installWidgetMenuItem)
		// MARK: Advanced
		advancedMenuItem.title = "Advanced".localized
		advancedMenuItem.view  = NSMenuItemCustomView(item: advancedMenuItem)
		/// START - Advanced submenu
		// MARK: Install (default widgets)
		reInstallDefaultWidgetsMenuItem.title  = "Re-Install Default Widgets".localized
		reInstallDefaultWidgetsMenuItem.action = #selector(installDefaultWidgets)
		// MARK: Show On-Board Screen
		showOnBoardScreenMenuItem.title  = "Show On-Board Screen".localized
		showOnBoardScreenMenuItem.action = #selector(showOnboardScreen)
		// MARK: Reload (Pock)
		reloadPockMenuItem.title  		 = "Reload Pock".localized
		reloadPockMenuItem.action 		 = #selector(reloadPock)
		reloadPockMenuItem.keyEquivalent = "r"
		reloadPockMenuItem.keyEquivalentModifierMask = .command
		// MARK: Relaunch (Pock)
		relaunchPockMenuItem.title 		   = "Relaunch Pock".localized
		relaunchPockMenuItem.action 	   = #selector(relaunchPock)
		relaunchPockMenuItem.keyEquivalent = "R"
		relaunchPockMenuItem.keyEquivalentModifierMask = .command
		// MARK: Relaunch (Touch Bar Agent)
		relaunchTouchBarAgentMenuItem.title 		= "Relaunch Touch Bar Agent".localized
		relaunchTouchBarAgentMenuItem.action 		= #selector(reloadTouchBarAgent)
		relaunchTouchBarAgentMenuItem.keyEquivalent = "a"
		relaunchTouchBarAgentMenuItem.keyEquivalentModifierMask = .command
		// MARK: Relaunch (Touch Bar Server)
		relaunchTouchBarServerMenuItem.title 		 = "Relaunch Touch Bar Server".localized
		relaunchTouchBarServerMenuItem.action 		 = #selector(reloadTouchBarServer)
		relaunchTouchBarServerMenuItem.keyEquivalent = "A"
		relaunchTouchBarServerMenuItem.keyEquivalentModifierMask = .command
		/// END - Advanced submenu
		// MARK: Support This Project
		supportThisProjectMenuItem.title  = "Support This Project".localized
		supportThisProjectMenuItem.action = #selector(openDonateURL)
		supportThisProjectMenuItem.view  = NSMenuItemCustomView(item: supportThisProjectMenuItem)
		// MARK: Quit Pock
		quitPockMenuItem.title  = "Quit Pock".localized
		quitPockMenuItem.target = NSApp
		quitPockMenuItem.action = #selector(NSApp.terminate)
		quitPockMenuItem.view  = NSMenuItemCustomView(item: quitPockMenuItem)
		// MARK: Set indentation level for advanced menu
		if #available(macOS 11, *) {
			return
		}
		advancedMenuItem.submenu?.items.forEach({ $0.indentationLevel = 1 })
	}
	internal func setUpdatesBadge(core: Int, widgets: Int, color: NSColor = .systemRed) {
		self.openPreferencesMenuItem.setBadge(core > 0 ? core.description : nil, color: color)
		self.openWidgetsManagerMenuItem.setBadge(widgets > 0 ? widgets.description : nil, color: color)
		if core + widgets > 0 {
			let base = pockStatusbarIcon.button
			let badge = NSView(frame: .zero)
			badge.wantsLayer = true
			badge.layer?.backgroundColor = NSColor.systemRed.cgColor
			badge.layer?.cornerRadius = 2
			base?.addSubview(badge)
			badge.snp.remakeConstraints {
				$0.height.width.equalTo(4)
				$0.right.equalToSuperview().inset(3)
				$0.bottom.equalToSuperview().inset(4)
			}
		}else {
			pockStatusbarIcon.button?.subviews.forEach({ $0.removeFromSuperview() })
		}
	}
    
    /// Preferences
    private let generalPreferencePane: GeneralPreferencePane = GeneralPreferencePane()
    private lazy var preferencesWindowController: PreferencesWindowController = {
        return PreferencesWindowController(preferencePanes: [generalPreferencePane])
    }()
    
    /// Widgets Manager
    private lazy var widgetsManagerWindowController: PreferencesWindowController = {
        return PreferencesWindowController(
            preferencePanes: [
                WidgetsManagerListPane(),
                WidgetsManagerInstallPane()
            ],
            hidesToolbarForSingleItem: false
        )
    }()
    
    /// Finish launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        /// Initialize Crashlytics
        #if !DEBUG
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") {
            if let secrets = NSDictionary(contentsOfFile: path) as? [String: String], let secret = secrets["AppCenter"] {
                UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
				AppCenter.start(withAppSecret: secret, services: [
					Analytics.self,
					Crashes.self
				])
            }
        }
        #endif
        
        /// Initialise Pock
		self.initialize()
		
		/// Show on board window controller
		if Defaults[.didShowOnboardScreen] == false {
			Defaults[.didShowOnboardScreen] = true
			self.showOnboardScreen()
		}
        
        /// Set Pock inactive
        NSApp.deactivate()

    }
    
    private func initialize() {
        /// Check for accessibility (needed for badges to work)
        self.checkAccessibility()
        
        /// Check for status bar icon
        if let button = pockStatusbarIcon.button {
            button.image = NSImage(named: "pock-inner-icon")
            button.image?.isTemplate = true
            /// Create menu
			setupMainMenuItems()
            pockStatusbarIcon.menu = mainMenu
        }
        
        /// Check for updates
        async(after: 1) { [weak self] in
			self?.checkForUpdates() { [weak self] in
				/// Present Pock
				self?.reloadPock()
			}
        }
        
        /// Register for notification
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(toggleAutomaticUpdatesTimer),
                                                          name: .shouldEnableAutomaticUpdates,
                                                          object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reloadPock),
                                                          name: .shouldReloadPock,
                                                          object: nil)
		NSWorkspace.shared.notificationCenter.addObserver(self,
														  selector: #selector(handleSleepWakeNotifications(_:)),
														  name: NSWorkspace.willSleepNotification,
														  object: nil)
		NSWorkspace.shared.notificationCenter.addObserver(self,
														  selector: #selector(handleSleepWakeNotifications(_:)),
														  name: NSWorkspace.didWakeNotification,
														  object: nil)
		/// Register for lock/unlock notifications
		DistributedNotificationCenter.default().addObserver(
			forName: .screenIsLocked, object: nil, queue: .main, using: { [weak self] _ in
				self?.screenIsLocked = true
				self?._handleSleepWakeNotifications(name: .screenIsLocked)
			}
		)
		DistributedNotificationCenter.default().addObserver(
			forName: .screenIsUnlocked, object: nil, queue: .main, using: { [weak self] _ in
				self?.screenIsLocked = false
				self?._handleSleepWakeNotifications(name: .screenIsUnlocked)
			}
		)
		
        toggleAutomaticUpdatesTimer()
        registerGlobalHotKey()
    }
	
	@objc private func handleSleepWakeNotifications(_ notification: Notification?) {
		self._handleSleepWakeNotifications(name: notification?.name)
	}
	
	private func _handleSleepWakeNotifications(name: Notification.Name?) {
		switch name {
		case NSWorkspace.willSleepNotification, Notification.Name.screenIsLocked:
			#if DEBUG
			NSLog("[Pock]: Dismissing Pock... Reason: \(name?.rawValue ?? "unknown") [screenIsLocked: \(screenIsLocked)]")
			#endif
			self.navController?.dismiss()
			self.navController = nil
		case NSWorkspace.didWakeNotification, Notification.Name.screenIsUnlocked:
			#if DEBUG
			NSLog("[Pock]: Presenting Pock... Reason: \(name?.rawValue ?? "unknown") [screenIsLocked: \(screenIsLocked)]")
			#endif
			if !screenIsLocked {
				self.reloadPock()
			}
		default:
			return
		}
	}
    
    @objc func reloadPock() {
        navController?.dismiss()
        navController = nil
        let mainController: PockMainController = PockMainController.load()
        navController = PKTouchBarNavigationController(rootController: mainController)
    }
    
    @objc func relaunchPock() {
        PockHelper.default.relaunchPock()
    }
	
	@objc func reloadTouchBarAgent() {
		TouchBarHelper.reloadTouchBarAgent()
	}
    
    @objc func reloadTouchBarServer() {
        TouchBarHelper.reloadTouchBarServer() { [weak self] success in
            if success {
                self?.reloadPock()
            }
        }
    }
    
    @objc func installDefaultWidgets() {
        PockHelper.default.installDefaultWidgets(nil)
    }
    
    private func registerGlobalHotKey() {
        if let keyCombo = KeyCombo(doubledCocoaModifiers: .control) {
            let hotKey = HotKey(identifier: "TogglePock", keyCombo: keyCombo, target: self, action: #selector(togglePock))
            hotKey.register()
        }
    }
    
    @objc private func togglePock() {
		if navController == nil || NSFunctionRow.activeFunctionRows().count == 1 {
            reloadPock()
        }else {
            navController?.dismiss()
            navController = nil
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
	@objc private func checkForUpdates(_ completion: @escaping () -> Void) {
        generalPreferencePane.hasLatestVersion(completion: { [weak self] latestVersion in
			async { [completion] in
				completion()
			}
			guard let latestVersion = latestVersion else {
				return
			}
            self?.generalPreferencePane.newVersionAvailable = (latestVersion)
            async { [weak self] in
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
    
    /// Open customization
    @objc private func openCustomization() {
        (navController?.rootController as? PockMainController)?.openCustomization()
    }
    
    /// Open widgets manager
    @objc internal func openWidgetsManager() {
		widgetsManagerWindowController.show(preferencePane: .widgets_manager_list)
    }
	
	@objc internal func openInstallWidgetsManager() {
		widgetsManagerWindowController.show(preferencePane: .widgets_manager_install)
	}
    
	/// Open website
	@objc private func openWebsite() {
		guard let url = URL(string: "https://pock.dev") else { return }
		NSWorkspace.shared.open(url)
	}
	
    /// Open donate url
    @objc private func openDonateURL() {
        guard let url = URL(string: "https://paypal.me/pigigaldi") else { return }
        NSWorkspace.shared.open(url)
    }
	
	/// Show On Board screen
	@objc private func showOnboardScreen() {
		let onboardController = OnboardWindowController()
		onboardController.showWindow(self)
	}
    
}
