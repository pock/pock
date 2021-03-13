//
//  AppController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation
import Magnet
import PockKit

internal struct MessageAction {
	internal enum Key: String {
		case none = "", esc = "\u{1b}", enter = "\r"
	}
	typealias MessageActionHandler = () -> Void
	let title: String
	let key: Key
	let action: MessageActionHandler?
	internal init(title: String, key: Key = .none, action: MessageActionHandler? = nil) {
		self.title = title
		self.key = key
		self.action = action
	}
}

internal class AppController: NSResponder {
	
	/// Singleton
	static let shared = AppController()

	/// Double `ctrl` hotkey
	private var doubleCtrlHotKey: HotKey?

	/// Private initialiser
	private override init() {
		super.init()
		_ = TouchBarHelper.swizzleFunctions
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
			if navigationController.visibleController?.isVisible == true {
				if NSFunctionRow.activeFunctionRows().count > 1 {
					TouchBarHelper.markTouchBarAsDimmed(true)
				} else {
					reload()
				}
			} else {
				TouchBarHelper.markTouchBarAsDimmed(false)
			}
		}
	}

	/// Register double `ctrl` hotkey
	private func registerDoubleControlHotKey() {
		doubleCtrlHotKey = HotKey(key: .control, double: true, target: self, selector: #selector(toggleVisibility))
	}
	
	// MARK: Show messages panel to inform users about certain situations
	internal func showMessagePanelWith(
		error: Error? = nil,
		title: String? = nil,
		message: String? = nil,
		style: NSAlert.Style = .informational,
		actions: [MessageAction] = []
	) {
		precondition(actions.count <= 4, "Invalid alert actions count. `NSAlert` can only have a maximum of 3 buttons other than `cancel`")
		precondition(actions.filter({ $0.key == .esc }).count <= 1, "Invalid number of `cancel` actions. Only one is allowed.")
		let alert = NSAlert()
		alert.messageText = title ?? "alert.title.default".localized
		alert.informativeText = message ?? "alert.message.default".localized
		alert.alertStyle = style
		if actions.isEmpty {
			let cancel = alert.addButton(withTitle: "base.cancel".localized)
			cancel.keyEquivalent = MessageAction.Key.esc.rawValue
		} else {
			actions.forEach({
				let button = alert.addButton(withTitle: $0.title)
				button.keyEquivalent = $0.key.rawValue
			})
		}
		NSApp.activate(ignoringOtherApps: true)
		defer {
			NSApp.deactivate()
		}
		switch alert.runModal() {
		case .alertFirstButtonReturn:
			actions[0].action?()
		case .alertSecondButtonReturn:
			actions[1].action?()
		case .alertThirdButtonReturn:
			actions[2].action?()
		default:
			return
		}
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
