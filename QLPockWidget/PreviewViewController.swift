//
//  PreviewViewController.swift
//  QLPockWidget
//
//  Created by Pierluigi Galdi on 14/05/21.
//

import Cocoa
import Quartz

private let preferredSize: NSSize = NSSize(width: 580, height: 256)

class PreviewViewController: NSViewController, QLPreviewingController {
	
	// MARK: UI Elements
	
	@IBOutlet private weak var iconView: NSImageView!
	@IBOutlet private weak var widgetNameLabel: NSTextField!
	@IBOutlet private weak var widgetVersionLabel: NSTextField!
	@IBOutlet private weak var widgetAuthorLabel: NSTextField!
	@IBOutlet private weak var widgetBundleIdentifierLabel: NSTextField!
	@IBOutlet private weak var unsignedWidgetDisclaimerLabel: NSTextField!
	
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
		async(after: 0.75) { [weak self] in
			guard let self = self else {
				return
			}
			self.iconView.image = NSImage(named: "widget-ql-icon")
			do {
				let widget = try PKWidgetInfo(path: url)
				self.widgetNameLabel.stringValue = widget.name
				self.widgetVersionLabel.stringValue = "Version \(widget.fullVersion)"
				self.widgetAuthorLabel.stringValue = widget.author
				self.widgetBundleIdentifierLabel.stringValue = widget.bundleIdentifier
				self.unsignedWidgetDisclaimerLabel.isHidden = true
				handler(nil)
			} catch {
				NSLog("[QLPockWidget]: Invalid widget: %@. Try getting information directly from `Info.plist`", error.localizedDescription)
				let plistPath = url.appendingPathComponent("Contents", isDirectory: true).appendingPathComponent("Info.plist")
				if let bundle = NSDictionary(contentsOfFile: plistPath.path),
				   let bundleIdentifier: String = bundle[.bundleIdentifier],
				   let name: String = bundle[.bundleName],
				   let author: String = bundle[.widgetAuthor],
				   let version: String = bundle[.bundleVersion] {
					self.widgetNameLabel.stringValue = name
					if let build: String = bundle[.bundleBuild], build != "1" {
						self.widgetVersionLabel.stringValue = "Version \(version)-\(build)"
					} else {
						self.widgetVersionLabel.stringValue = "Version \(version)"
					}
					self.widgetAuthorLabel.stringValue = author
					self.widgetBundleIdentifierLabel.stringValue = bundleIdentifier
					self.unsignedWidgetDisclaimerLabel.isHidden = false
					handler(nil)
				} else {
					handler(error)
				}
			}
		}
	}

}

extension NSDictionary {
	fileprivate subscript<T>(_ key: PKWidgetInfo.BundleKeys) -> T? {
		return value(forKey: key.rawValue) as? T
	}
}
