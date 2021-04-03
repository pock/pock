//
//  NSMenuHeader.swift
//  Pock
//
//  Created by Pierluigi Galdi on 03/04/21.
//

import Cocoa

@IBDesignable
internal class NSMenuHeader: NSView {

	@IBOutlet internal private(set) weak var view: NSView!
	@IBOutlet internal private(set) weak var mainLabel: NSTextField!

	internal weak var item: NSMenuItem?
	
	internal static func new(title: String) -> NSMenuItem {
		let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
		item.view = NSMenuHeader(item: item)
		return item
	}

	convenience init(item: NSMenuItem, height: CGFloat = 26) {
		self.init(frame: .zero)
		self.item = item
		self.item?._setViewHandlesEvents(false)
		self.translatesAutoresizingMaskIntoConstraints = false
		self.heightAnchor.constraint(equalToConstant: height).isActive = true
		let frameworkBundle = Bundle(for: Self.self)
		guard frameworkBundle.loadNibNamed("\(type(of: self))", owner: self, topLevelObjects: nil) else {
			fatalError("Can't find nib for name: `\(type(of: self))`")
		}
		addSubview(view)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
		view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
		view.topAnchor.constraint(equalTo: topAnchor).isActive = true
		view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
		layoutSubtreeIfNeeded()
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		mainLabel.textColor = .tertiaryLabelColor
	}

	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		mainLabel.stringValue = item?.title ?? ""
	}
}
