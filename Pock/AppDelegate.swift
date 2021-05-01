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

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	/// MenuBar item and menu
	private let mainBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
	private let mainBarMenu = NSMenu(title: "Pock")

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		/// Set Roger allowed log levels
		Roger.allowedLevels = [.error, .debug]
		
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

		/// Initialise AppController
		AppController.shared.prepareTouchBar()

		/// Deactivate Pock
		NSApp.deactivate()
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
	
	// MARK: Debug menu
	#if DEBUG
	private lazy var _debugMenuItem: NSMenuItem = {
		let debugMenu = NSMenu(title: "PockDebug")
		debugMenu.addItem(withTitle: "Toggle Touch Bar visibility", action: #selector(toggleTouchBarVisibility), keyEquivalent: "")
		debugMenu.addItem(withTitle: "Show debug console…", action: #selector(showDebugConsole), keyEquivalent: "c")
		debugMenu.addItem(NSMenuHeader.new(title: "Widget's Bundles"))
		debugMenu.addItem(withTitle: "Unload All Widgets", action: #selector(unloadAllWidgets), keyEquivalent: "")
		debugMenu.addItem(withTitle: "Reload Widgets", action: #selector(reloadWidgets), keyEquivalent: "")
		debugMenu.addItem(withTitle: "Relaunch Pock", action: #selector(relaunch), keyEquivalent: "")
		let debugMenuItem = NSMenuItem(title: "Debug…", action: nil, keyEquivalent: "")
		debugMenuItem.submenu = debugMenu
		debugMenuItem.view = NSMenuItemCustomView(item: debugMenuItem)
		return debugMenuItem
	}()
	#endif

	// MARK: Main bar menu items
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
		mainBarMenu.addItem(NSMenuItemCustomView.new(
			title: "menu.preferences".localized,
			target: self,
			selector: #selector(openPreferences),
			keyEquivalent: ","
		))
		
		// MARK: Widget's manager
		mainBarMenu.addItem(NSMenuItemCustomView.new(
			title: "menu.manage-widgets".localized,
			target: self,
			selector: #selector(openWidgetsManager),
			keyEquivalent: "m"
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
			keyEquivalent: "s"
		))

		#if DEBUG
		// MARK: Debug
		mainBarMenu.addItem(NSMenuHeader.new(title: "Debug"))
		mainBarMenu.addItem(_debugMenuItem)
		#endif
		
		// MARK: Quit Pock
		mainBarMenu.addItem(.separator())
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

	// MARK: Open website
	@objc private func openWebsite() {
		guard let url = URL(string: "base.website_url".localized) else { return }
		NSWorkspace.shared.open(url)
	}
	
	// MARK: Open preferences
	@objc private func openPreferences() {
		// TODO: To be implemented
	}
	
	// MARK: Opwn widgets manager
	@objc private func openWidgetsManager() {
		let controller = WidgetsManagerViewController()
		let window = NSWindow(contentViewController: controller)
		window.titleVisibility = .hidden
		window.isReleasedWhenClosed = true
		let windowController = NSWindowController(window: window)
		windowController.showWindow(nil)
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

}

#if DEBUG
private extension AppDelegate {
	// MARK: Toggle Touch Bar visibility
	@objc private func toggleTouchBarVisibility() {
		AppController.shared.toggleVisibility()
	}
	// MARK: Show debug console
	@objc private func showDebugConsole() {
		// TODO: AppController.shared.showDebugConsole()
	}
	// MARK: Unload All Widgets
	@objc private func unloadAllWidgets() {
		AppController.shared.unloadAllWidgets()
	}
	// MARK: Reload Widgets
	@objc private func reloadWidgets() {
		AppController.shared.reloadWidgets()
	}
	// MARK: Relaunch Pock
	@objc private func relaunch() {
		AppController.shared.relaunch()
	}
}
#endif
