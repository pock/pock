//
//  PreviewViewController.swift
//  QLPockWidget
//
//  Created by Pierluigi Galdi on 14/05/21.
//

import Cocoa
import Quartz

private let preferredSize: NSSize = NSSize(width: 480, height: 190)

class PreviewViewController: NSViewController, QLPreviewingController {
    
	// MARK: UI Elements
	
	@IBOutlet private weak var iconView: NSImageView!
	@IBOutlet private weak var widgetNameLabel: NSTextField!
	@IBOutlet private weak var widgetVersionLabel: NSTextField!
	@IBOutlet private weak var widgetAuthorLabel: NSTextField!
	@IBOutlet private weak var widgetBundleIdentifierLabel: NSTextField!
	
	// MARK: Overrides
	
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }
	
	override var preferredMinimumSize: NSSize {
		return preferredSize
	}
	
	override var preferredMaximumSize: NSSize {
		return preferredSize
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		preferredContentSize = preferredSize
	}
	
	func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
		do {
			/// load widget entity
			let widget = try PKWidgetInfo(path: url)
			/// set widget icon
			iconView.image = NSImage(named: "widget-icon")
			/// set widget data
			widgetNameLabel.stringValue = widget.name
			widgetVersionLabel.stringValue = widget.fullVersion
			widgetAuthorLabel.stringValue = widget.author
			widgetBundleIdentifierLabel.stringValue = widget.bundleIdentifier
			/// call handler
			handler(nil)
		} catch {
			handler(error)
		}
	}

}
