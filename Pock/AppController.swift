//
//  AppController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation
import Magnet
import PockKit

internal class AppController: NSResponder {

	/// Singleton
	static let shared = AppController()

	/// Double `ctrl` hotkey
	private var doubleCtrlHotKey: HotKey?

	/// Private initialiser
	private override init() {
		super.init()
		registerDoubleControlHotKey()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// Core
	private(set) var navigationController: PKTouchBarNavigationController!
	private(set) var pockTouchBarController: PockTouchBarController!

	/// Setup
	internal func prepareTouchBar() {
		pockTouchBarController = PockTouchBarController.load()
		navigationController = PKTouchBarNavigationController(rootController: pockTouchBarController)
	}

	/// Dismiss
	internal func tearDownTouchBar() {
		navigationController?.dismiss()
		pockTouchBarController = nil
		navigationController = nil
	}

	/// Reload
	@objc internal func reload() {
		tearDownTouchBar()
		dsleep(0.1)
		prepareTouchBar()
	}

	/// Toggle
	@objc internal func toggleVisibility() {
		if pockTouchBarController == nil {
			prepareTouchBar()
		} else {
			if NSFunctionRow.activeFunctionRows().count == 1 {
				reload()
			} else {
				tearDownTouchBar()
			}
		}
	}

	/// Register double `ctrl` hotkey
	private func registerDoubleControlHotKey() {
		doubleCtrlHotKey = HotKey(key: .control, double: true, target: self, selector: #selector(toggleVisibility))
	}

}

// MARK: Customization menu
extension AppController: NSTouchBarDelegate {
	
	/// Open customization menu
	@objc internal func openCustomizationPalette() {
		if pockTouchBarController == nil {
			return
		}
		pockTouchBarController.minimize()
		NSApp.touchBar = makeTouchBar()
		addCustomizationObservers()
		async(after: 0.375) {
			NSApp.toggleTouchBarCustomizationPalette(self)
		}
	}
	
	override func makeTouchBar() -> NSTouchBar? {
		let touchBar = NSTouchBar()
		touchBar.delegate = self
		touchBar.customizationIdentifier = .pockTouchBarController
		touchBar.customizationAllowedItemIdentifiers = pockTouchBarController.allowedCustomizationIdentifiers
		return touchBar
	}
	
	func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
		guard let widget = pockTouchBarController.touchBar?.item(forIdentifier: identifier) as? PKWidgetTouchBarItem else {
			Roger.error("Can't find `NSTouchBarItem` for given identifier: `\(identifier)`")
			return nil
		}
		let item = NSCustomTouchBarItem(identifier: identifier)
		item.view = widget.viewForCustomizationPalette()
		item.customizationLabel = widget.customizationLabel
		return item
	}
	
	private func addCustomizationObservers() {
		NotificationCenter.default.addObserver(self,
											   selector: #selector(didExitCustomization(_:)),
											   name: NSNotification.Name("NSTouchBarDidExitCustomization"),
											   object: nil)
	}
	
	private func removeCustomizationObservers() {
		NotificationCenter.default.removeObserver(self,
												  name: NSNotification.Name("NSTouchBarDidExitCustomization"),
												  object: nil)
	}
	
	@objc private func delayedOpenCustomization() {
		NSApp.toggleTouchBarCustomizationPalette(nil)
	}
	
	@objc private func didExitCustomization(_ sender: Any?) {
		NSApp.touchBar = nil
		pockTouchBarController.present()
	}
	
}
