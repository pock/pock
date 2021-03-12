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
		let aboutPockMenuItem = NSMenuItem(title: "menu.about".localized, action: #selector(openWebsite), keyEquivalent: "")
		aboutPockMenuItem.view = NSMenuItemCustomView(item: aboutPockMenuItem)
		mainBarMenu.addItem(aboutPockMenuItem)

		// MARK: Customize Touch Bar
		let customizeTouchBarMenuItem = NSMenuItem(title: "menu.open_customization_palette".localized, action: #selector(openCustomizationPalette), keyEquivalent: "c")
		customizeTouchBarMenuItem.view = NSMenuItemCustomView(item: customizeTouchBarMenuItem)
		mainBarMenu.addItem(customizeTouchBarMenuItem)
		
		// MARK: Quit Pock
		let quitPockMenuItem = NSMenuItem(title: "menu.quit".localized, action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
		quitPockMenuItem.target = NSApp
		quitPockMenuItem.view = NSMenuItemCustomView(item: quitPockMenuItem)
		mainBarMenu.addItem(quitPockMenuItem)

		// MARK: Set indentation level for advanced menu
		if #available(macOS 11, *) {
			return
		}
		// FIXME: advancedMenuItem.submenu?.items.forEach({ $0.indentationLevel = 1 })
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
