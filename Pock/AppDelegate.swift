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

	private func setupMainBarMenuItems() {
		/// Set title and actions

		// MARK: About Pock
		mainBarMenu.addItem(NSMenuHeader.new(title: "menu.general".localized))
		mainBarMenu.addItem(NSMenuItemCustomView.new(
			title: "menu.about".localized,
			target: self,
			selector: #selector(openWebsite),
			keyEquivalent: nil
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

		// MARK: Debug
		#if DEBUG
		mainBarMenu.addItem(NSMenuHeader.new(title: "Debug"))
		let debugMenu = NSMenu(title: "PockDebug")
		debugMenu.addItem(withTitle: "Toggle Touch Bar visibility", action: #selector(toggleTouchBarVisibility), keyEquivalent: "")
		debugMenu.addItem(withTitle: "Show debug console…", action: #selector(showDebugConsole), keyEquivalent: "c")
		debugMenu.addItem(.separator())
		debugMenu.addItem(withTitle: "Relaunch Pock", action: #selector(relaunch), keyEquivalent: "")
		let debugMenuItem = NSMenuItem(title: "Debug…", action: nil, keyEquivalent: "")
		debugMenuItem.submenu = debugMenu
		debugMenuItem.view = NSMenuItemCustomView(item: debugMenuItem)
		mainBarMenu.addItem(debugMenuItem)
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
	
	// MARK: Open customization menu
	@objc private func openCustomizationPalette() {
		AppController.shared.openCustomizationPalette()
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
	// MARK: Relaunch Pock
	@objc private func relaunch() {
		AppController.shared.relaunch()
	}
}
#endif
