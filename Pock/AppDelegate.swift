//
//  AppDelegate.swift
//  Pock
//
//  Created by Pierluigi Galdi on 09/03/21.
//

import Cocoa
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

// swiftlint:disable type_body_length
@main
class AppDelegate: NSObject, NSApplicationDelegate {

	/// MenuBar item and menu
	private let mainBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
	private let mainBarMenu = NSMenu(title: "Pock")
	
	private var preferencesMenuItem: NSMenuBadgeItem!
	private var manageWidgetsMenuItem: NSMenuBadgeItem!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		/// Set Roger allowed log levels
		#if DEBUG
		Roger.allowedLevels = [.error, .debug]
		// ecxc-tyop-fwqo-eznp
		#else
		Roger.allowedLevels = []
		#endif
		
		/// Initialise AppCenter stuff (Analytics & Crash)
		#if !DEBUG
		if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") {
			if let secrets = NSDictionary(contentsOfFile: path) as? [String: String], let secret = secrets["AppCenter"] {
				AppCenter.start(withAppSecret: secret, services: [
					Analytics.self,
					Crashes.self
				])
			}
		}
		#endif

		/// Add main bar menu item
		addMainBarItem()

		/// Register for notifications
		NotificationCenter.default.addObserver(self, selector: #selector(updateMenuItemsAfterLatestVersionsFetch), name: .didFetchLatestVersions, object: nil)
		
		/// Load installed widgets and prepare touch bar
		AppController.shared.reloadWidgets {
			AppController.shared.fetchLatestVersions {}
			AppController.shared.prepareTouchBar()
		}

		/// Deactivate Pock
		NSApp.deactivate()
		
		/// Show On-Board window, if needed
		if Preferences[.didShowOnBoard] == false {
			openOnBoardController()
		}

	}
	
	func applicationWillTerminate(_ notification: Notification) {
		/// Tear down Pock to be sure to reset user defined Touch Bar settings.
		AppController.shared.tearDownTouchBar()
	}

	// MARK: Setup main bar menu items
	private func addMainBarItem() {
		if let button = mainBarItem.button {
			button.image = NSImage(named: .pockInnerIcon)
			button.image?.isTemplate = true
			/// Create menu
			setupMainBarMenuItems()
			mainBarItem.menu = mainBarMenu
		}
	}
	
	// MARK: Advanced menu
	private lazy var advancedMenuItem: NSMenuItem = {
		let menu = NSMenu(title: "menu.advanced".localized)
		menu.addItem(NSMenuHeader.new(title: "menu.widgets".localized))
		menu.addItem(NSMenuItemCustomView.new(
			title: "menu.advanced.re-install-default-widgets".localized,
			target: self,
			selector: #selector(selectAdvancedSectionItem(_:)),
			keyEquivalent: "w"
		))
        menu.addItem(NSMenuItemCustomView.new(
            title: "menu.advanced.open-widgets-folder".localized,
            target: self,
            selector: #selector(selectAdvancedSectionItem(_:)),
            keyEquivalent: "f"
        ))
		menu.addItem(NSMenuHeader.new(title: "general.action.reload".localized))
		menu.addItem(NSMenuItemCustomView.new(
			title: "menu.advanced.reload_pock".localized,
			target: self,
			selector: #selector(selectAdvancedSectionItem(_:)),
			keyEquivalent: "r"
		))
		menu.addItem(NSMenuItemCustomView.new(
			title: "menu.advanced.relaunch_pock".localized,
			target: self,
			selector: #selector(selectAdvancedSectionItem(_:)),
			keyEquivalent: "R",
			isAlternate: true
		))
		menu.addItem(NSMenuItemCustomView.new(
			title: "menu.advanced.reload_touchbar".localized,
			target: self,
			selector: #selector(selectAdvancedSectionItem(_:)),
			keyEquivalent: "s"
		))
		menu.addItem(NSMenuItemCustomView.new(
			title: "menu.advanced.relaunch_touchbar".localized,
			target: self,
			selector: #selector(selectAdvancedSectionItem(_:)),
			keyEquivalent: "S",
			isAlternate: true
		))
        menu.addItem(NSMenuHeader.new(title: "menu.developers".localized))
        menu.addItem(NSMenuItemCustomView.new(
            title: "menu.advanced.show_debug_console".localized,
            target: self,
            selector: #selector(selectAdvancedSectionItem(_:)),
            keyEquivalent: "d"
        ))
		let menuItem = NSMenuItem(title: "menu.advanced".localized, action: nil, keyEquivalent: "")
		menuItem.submenu = menu
		menuItem.view = NSMenuItemCustomView(item: menuItem)
		return menuItem
	}()
	
	// MARK: Debug menu
	#if DEBUG
	private lazy var _debugMenuItem: NSMenuItem = {
		let debugMenu = NSMenu(title: "PockDebug")
		debugMenu.addItem(NSMenuHeader.new(title: "Widgets"))
		debugMenu.addItem(withTitle: "Reload Widgets", action: #selector(reloadWidgets), keyEquivalent: "")
		debugMenu.addItem(NSMenuHeader.new(title: "General"))
		debugMenu.addItem(withTitle: "Open On-Board…", action: #selector(openOnBoardController), keyEquivalent: "")
		debugMenu.addItem(withTitle: "Toggle Touch Bar visibility", action: #selector(toggleTouchBarVisibility), keyEquivalent: "")
		debugMenu.addItem(withTitle: "Relaunch Pock", action: #selector(relaunch), keyEquivalent: "")
		let debugMenuItem = NSMenuItem(title: "Debug…", action: nil, keyEquivalent: "")
		debugMenuItem.submenu = debugMenu
		debugMenuItem.view = NSMenuItemCustomView(item: debugMenuItem)
		return debugMenuItem
	}()
	#endif

	// MARK: Main bar menu items
	// swiftlint:disable function_body_length
	private func setupMainBarMenuItems() {
		// MARK: About Pock
		mainBarMenu.addItem(NSMenuHeader.new(title: "menu.general".localized, height: 22))
		mainBarMenu.addItem(NSMenuItemCustomView.new(
			title: "menu.about".localized,
			target: self,
			selector: #selector(openWebsite),
			keyEquivalent: nil
		))
		
		// MARK: Preferences
		preferencesMenuItem = NSMenuBadgeItemView.item(
			title: "menu.preferences".localized,
			target: self,
			selector: #selector(openPreferences),
			keyEquivalent: ","
		)
		mainBarMenu.addItem(preferencesMenuItem)
		
		// MARK: Widgets
		mainBarMenu.addItem(NSMenuHeader.new(title: "menu.widgets".localized))
		manageWidgetsMenuItem = NSMenuBadgeItemView.item(
			title: "menu.widgets.manage-widgets".localized,
			target: self,
			selector: #selector(openWidgetsManager),
			keyEquivalent: "m"
		)
		mainBarMenu.addItem(manageWidgetsMenuItem)
		mainBarMenu.addItem(NSMenuItemCustomView.new(
			title: "menu.widgets.install-widget".localized,
			target: self,
			selector: #selector(openWidgetInstallPanel),
			keyEquivalent: "i"
		))
		
		// MARK: Customize Touch Bar
		mainBarMenu.addItem(NSMenuHeader.new(title: "menu.customization".localized))
		mainBarMenu.addItem(NSMenuItemCustomView.new(
			title: "menu.customization.pock".localized,
			target: self,
			selector: #selector(openCustomizationPalette),
			keyEquivalent: "p"
		))
		mainBarMenu.addItem(NSMenuItemCustomView.new(
			title: "menu.customization.control-strip".localized,
			target: self,
			selector: #selector(openCustomizationPalette),
			keyEquivalent: "c"
		))
		
		// MARK: Advanced
		mainBarMenu.addItem(NSMenuHeader.new(title: "menu.advanced".localized))
		mainBarMenu.addItem(advancedMenuItem)

		#if DEBUG
		// MARK: Debug
		mainBarMenu.addItem(NSMenuHeader.new(title: "Debug"))
		mainBarMenu.addItem(_debugMenuItem)
		#endif
		
		// MARK: Quit Pock
		mainBarMenu.addItem(NSMenuHeader.new(title: "menu.goodbye".localized))
		mainBarMenu.addItem(NSMenuItemCustomView.new(
			title: "menu.quit".localized,
			target: NSApp,
			selector: #selector(NSApp.terminate(_:)),
			keyEquivalent: "q"
		))
		
		// MARK: Set indentation level for advanced menu
		if #available(macOS 11, *) {
			return
		}
	}
	// swiftlint:enable function_body_length
	
	// MARK: Update menu items for new versions
	@objc private func updateMenuItemsAfterLatestVersionsFetch() {
		guard let latestVersions = Updater.cachedLatestReleases else {
			return
		}
		var coreBadge: Int = 0
        if latestVersions.core.name.isGreatherThan(Updater.fullAppVersion) {
			coreBadge = 1
		}
		var widgetsToUpdate: Int = 0
		for widget in WidgetsLoader.installedWidgets {
            let newVersion = Updater.newVersion(for: widget)
            if newVersion.version != nil || newVersion.error != nil {
				widgetsToUpdate += 1
			}
		}
		async { [weak self, coreBadge, widgetsToUpdate] in
			guard let self = self else {
				return
			}
			self.preferencesMenuItem.setBadge(coreBadge > 0 ? "\(coreBadge)" : nil)
			self.manageWidgetsMenuItem.setBadge(widgetsToUpdate > 0 ? "\(widgetsToUpdate)" : nil)
			if coreBadge + widgetsToUpdate > 0 {
				let base = self.mainBarItem.button
				let badge = NSView(frame: .zero)
				badge.wantsLayer = true
				badge.layer?.backgroundColor = NSColor.systemRed.cgColor
				badge.layer?.cornerRadius = 2
				base?.addSubview(badge)
				badge.height(4)
				badge.width(4)
				badge.rightToSuperview(offset: -3)
				badge.bottomToSuperview(offset: -4)
			} else {
				self.mainBarItem.button?.subviews.forEach({ $0.removeFromSuperview() })
			}
		}
	}

	// MARK: Open website
	@objc private func openWebsite() {
		AppController.shared.openWebsite()
	}
	
	// MARK: Open preferences
	@objc private func openPreferences() {
		AppController.shared.openController(PreferencesViewController())
	}
	
	// MARK: Open widgets manager
	@objc private func openWidgetsManager() {
		AppController.shared.openController(WidgetsManagerViewController())
	}
	
	// MARK: Open widget install panel
	@objc private func openWidgetInstallPanel() {
		let controller = WidgetsManagerViewController()
		AppController.shared.openController(controller)
		controller.presentWidgetInstallPanel(withInitialState: .dragdrop)
	}
	
	// MARK: Open customization menu
	@objc private func openCustomizationPalette(_ sender: NSMenuItem) {
		switch sender.keyEquivalent {
		case "p":
			AppController.shared.openPockCustomizationPalette()
		case "s":
			AppController.shared.openControlStripCustomizationPalette()
		default:
			return
		}
	}
	
	// MARK: Select advanced section item
	@objc private func selectAdvancedSectionItem(_ sender: NSMenuItem) {
        switch sender.keyEquivalent {
        case "w":
			AppController.shared.reInstallDefaultWidgets()
        case "f":
            NSWorkspace.shared.open(kWidgetsPathURL)
        case "r":
            AppController.shared.reload(shouldFetchLatestVersions: true)
        case "R":
            AppController.shared.relaunch()
        case "s":
            TouchBarHelper.reloadTouchBarAgent()
        case "S":
            TouchBarHelper.reloadTouchBarServer { _ in
                NSApp.activate(ignoringOtherApps: true)
            }
        case "d":
            AppController.shared.showDebugConsole()
        default:
            return
        }
	}
	
	// MARK: Open On-Board window
	@objc private func openOnBoardController() {
		AppController.shared.openController(OnBoardViewController())
	}
    
    // MARK: Show debug console
    @objc private func showDebugConsole() {
        AppController.shared.showDebugConsole()
    }

}
// swiftlint:enable type_body_length

#if DEBUG
private extension AppDelegate {
	// MARK: Toggle Touch Bar visibility
	@objc private func toggleTouchBarVisibility() {
		AppController.shared.toggleVisibility()
	}
	// MARK: Reload Widgets
	@objc private func reloadWidgets() {
		AppController.shared.reloadWidgets {}
	}
	// MARK: Relaunch Pock
	@objc private func relaunch() {
		AppController.shared.relaunch()
	}
}
#endif
