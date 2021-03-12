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
		widgets.removeAll()
		touchBar = nil
	}

	override func present() {
		guard isVisible == false else {
			return
		}
		loadInstalledWidgets { [weak self] in
			self?.invalidateTouchBar()
			self?.isVisible = true
			self?.presentWithPlacement(placement: 1)
		}
	}
	
	override func dismiss() {
		guard isVisible else {
			return
		}
		TouchBarHelper.setPresentationMode(to: .appWithControlStrip)
		super.dismiss()
	}
	
	private func flushWidgetItems() {
		cachedItems.removeAll()
	}

	/// Custom `presentWithPlacement` implementation
	private func presentWithPlacement(placement: Int64) {
		defer {
			DFRSystemModalShowsCloseBoxWhenFrontMost(false)
		}
		if #available (macOS 10.14, *) {
			NSTouchBar.presentSystemModalTouchBar(touchBar, placement: placement, systemTrayItemIdentifier: .pockControlStripItem)
		} else {
			NSTouchBar.presentSystemModalFunctionBar(touchBar, placement: placement, systemTrayItemIdentifier: .pockControlStripItem)
		}
	}
	
	/// Load installed widgets
	private func loadInstalledWidgets(_ completion: @escaping () -> Void) {
		WidgetsLoader().loadInstalledWidgets { [unowned self] widgets in
			for widget in widgets {
				self.widgets[widget.identifier] = widget
			}
			completion()
		}
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
