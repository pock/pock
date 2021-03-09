//
//  PKWidgetTouchBarItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 11/03/21.
//

import AppKit
import PockKit

internal class PKWidgetTouchBarItem: NSCustomTouchBarItem {
	
	/// Data
	internal private(set) var widget: PKWidget?
	
	/// Overrides
	override var customizationLabel: String! {
		get {
			return widget?.customizationLabel
		}
		set {
			widget?.customizationLabel = newValue
		}
	}
	
	/// Initialiser
	convenience init(widget: PKWidget.Type) {
		self.init(identifier: widget.identifier)
		self.widget = widget.init()
		viewController = PKWidgetViewController(item: self)
	}
	
	deinit {
		Roger.debug("[\(identifier.rawValue)][item] - deinit")
		widget = nil
	}
	
	private var viewSnapshot: NSImage {
		return NSImage(data: view.dataWithPDF(inside: view.bounds)) ?? NSImage(named: .pockInnerIcon)!
	}
	
	override func viewForCustomizationPalette() -> NSView? {
		Roger.info("[\(identifier)] - Snapshotting view for customization palette...")
		return NSImageView(image: viewSnapshot)
	}
	
	override func viewForCustomizationPreview() -> NSView? {
		Roger.info("[\(identifier)] - Snapshotting view for customization preview...")
		return NSImageView(image: viewSnapshot)
	}
	
}
