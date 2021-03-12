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
	
	private var defaultSnapshotView: NSView {
		return NSImageView(image: NSImage(named: .pockInnerIcon)!) // TODO: Change with default widget icon
	}
	
	private var snapshotView: NSView {
		if view.frame.width == 0 {
			view.frame.size = view.fittingSize
		}
		if let bitmapImage = view.bitmapImageRepForCachingDisplay(in: view.frame) {
			view.cacheDisplay(in: view.frame, to: bitmapImage)
			if let cgImage = bitmapImage.cgImage {
				return NSImageView(image: NSImage(cgImage: cgImage, size: view.frame.size))
			}
		}
		return defaultSnapshotView
	}
	
	override func viewForCustomizationPalette() -> NSView {
		Roger.info("[\(identifier)] - Snapshotting view for customization palette...")
		return snapshotView
	}
	
	override func viewForCustomizationPreview() -> NSView {
		Roger.info("[\(identifier)] - Snapshotting view for customization preview...")
		return snapshotView
	}
	
}
