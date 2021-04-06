//
//  PockTouchBarController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation
import PockKit

/// Customization identifier
extension NSTouchBar.CustomizationIdentifier {
	static let pockTouchBarController = "PockTouchBarController"
}

/// Control Strip item identifier
extension NSTouchBarItem.Identifier {
	static let pockControlStripItem = NSTouchBarItem.Identifier("PockControlStripItem")
}

/// Pock (main Touch Bar controller)
internal class PockTouchBarController: PKTouchBarMouseController {

	/// Data
	private(set) var widgets: [NSTouchBarItem.Identifier: PKWidget.Type] = [:]
	private(set) var cachedItems: [NSTouchBarItem.Identifier: PKWidgetTouchBarItem] = [:]
	
	internal var allowedCustomizationIdentifiers: [NSTouchBarItem.Identifier] {
		return Array(widgets.keys) + [.flexibleSpace]
	}
	
	/// Overrides
	override func didLoad() {
		Roger.debug("[PockTouchBarController] Loaded.")
	}
	
	deinit {
		Roger.info("Deinit")
		flushWidgetItems()
		touchBar = nil
	}

	override func present() {
		guard isVisible == false else {
			return
		}
		loadInstalledWidgets { [weak self] in
			self?.invalidateTouchBar()
		}
		isVisible = true
		if #available (macOS 10.14, *) {
			NSTouchBar.presentSystemModalTouchBar(touchBar, placement: 0, systemTrayItemIdentifier: nil)
		} else {
			NSTouchBar.presentSystemModalFunctionBar(touchBar, placement: 0, systemTrayItemIdentifier: nil)
		}
		TouchBarHelper.hideCloseButtonIfNeeded()
	}
	
	override func dismiss() {
		guard isVisible else {
			return
		}
		TouchBarHelper.setPresentationMode(to: .appWithControlStrip)
		super.dismiss()
	}

	/// Load/unload installed widgets
	private func loadInstalledWidgets(_ completion: @escaping () -> Void) {
		WidgetsLoader().loadInstalledWidgets { [unowned self] widgets in
			for widget in widgets {
				self.widgets[NSTouchBarItem.Identifier(widget.identifier)] = widget
			}
			completion()
		}
	}
	
	private func flushWidgetItems() {
		cachedItems.removeAll()
		widgets.removeAll()
	}

	/// Setup Touch Bar
	override func makeTouchBar() -> NSTouchBar? {
		let touchBar = NSTouchBar()
		touchBar.delegate = self
		touchBar.customizationIdentifier = .pockTouchBarController
		touchBar.customizationAllowedItemIdentifiers = allowedCustomizationIdentifiers
		for key in widgets.keys {
			Roger.info("[\(key.rawValue)] - Allowed for customization")
		}
		return touchBar
	}

	/// Make Touch Bar item for given identifier
	func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
		guard let widget = widgets[identifier] else {
			Roger.error("Can't find `NSTouchBarItem` for given identifier: `\(identifier)`")
			return nil
		}
		if let item = cachedItems[identifier] {
			Roger.info("[\(identifier.rawValue)][item] - cached")
			return item
		}
		Roger.info("[\(identifier.rawValue)][item] - initializes")
		let item = PKWidgetTouchBarItem(widget: widget)
		cachedItems[identifier] = item
		return item
	}

}
