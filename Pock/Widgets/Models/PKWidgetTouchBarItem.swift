//
//  PKWidgetTouchBarItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 11/03/21.
//

import AppKit
import PockKit
import TinyConstraints

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
		self.init(identifier: NSTouchBarItem.Identifier(widget.identifier))
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
		if let customImage = widget?.imageForCustomization {
			return NSImageView(image: customImage)
		}
		let width = view.frame.width == 0 ? view.fittingSize.width : view.frame.width
		let frame = NSRect(x: 0, y: 0, width: width, height: 30)
		guard let button = view as? NSButton else {
			guard let image = NSImage(frame: frame, view: view) else {
				return defaultSnapshotView
			}
			return NSImageView(image: image)
		}
		/// Special setup for NSButtons
		let previousButtonStyle = button.bezelStyle
		button.bezelStyle = .roundRect
		button.subviews.filter({ $0.description.contains("NSButtonBezelView") }).forEach({
			$0.alphaValue = 0
		})
		defer {
			button.subviews.filter({ $0.description.contains("NSButtonBezelView") }).forEach({
				$0.alphaValue = 1
			})
			button.bezelStyle = previousButtonStyle
		}
		guard let image = NSImage(frame: frame, view: button) else {
			return defaultSnapshotView
		}
		let imageView = NSImageView(image: image)
		let returnableView = NSView(frame: .zero)
		returnableView.wantsLayer = true
		returnableView.layer?.backgroundColor = NSColor(red: 45/255, green: 41/255, blue: 44/255, alpha: 1).cgColor
		returnableView.layer?.cornerRadius = 6.25
		returnableView.layer?.masksToBounds = true
		returnableView.addSubview(imageView)
		imageView.edgesToSuperview(insets: .horizontal(returnableView is NSButton ? 0 : 8))
		return returnableView
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
