//
//  NSMenuBadgeItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 22/01/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation

internal class NSMenuItemCustomView: NSView {
	internal var item: NSMenuItem {
		return enclosingMenuItem!
	}
	override func awakeFromNib() {
		super.awakeFromNib()
		item._setViewHandlesEvents(false)
	}
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		for label in findViews(subclassOf: NSTextField.self).filter({ [1,2].contains($0.tag) }) {
			label.textColor = item.isHighlighted ? .white : .tertiaryLabelColor
			if label.tag == 1 {
				label.font = NSFont.systemFont(ofSize: 14, weight: item.isHighlighted ? .regular : .semibold)
			}
		}
	}
}

internal class NSMenuBadgeItemView: NSMenuItemCustomView {
	@IBOutlet internal private(set) weak var mainLabel: NSTextField?
	@IBOutlet internal private(set) weak var badge: 	NSTextField!
	@IBOutlet internal private(set) weak var keyModifier: NSTextField!
	@IBOutlet internal private(set) weak var keyChar: 	  NSTextField!
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		self.badge.layer?.cornerRadius = self.badge.frame.height / 2
	}
	override func awakeFromNib() {
		super.awakeFromNib()
		mainLabel?.stringValue = item.title
		keyModifier.stringValue = item.keyEquivalentModifierMask.keyEquivalentStrings().joined()
		keyChar.stringValue = item.keyEquivalent.uppercased()
		badge.isHidden = true
	}
}

internal class NSMenuBadgeItem: NSMenuItem {
	
	private var _view: NSMenuBadgeItemView {
		return view as! NSMenuBadgeItemView
	}
	
	override var title: String {
		didSet {
			_view.mainLabel?.stringValue = title
		}
	}
	
	override var keyEquivalentModifierMask: NSEvent.ModifierFlags {
		didSet {
			_view.keyModifier.stringValue = keyEquivalentModifierMask.keyEquivalentStrings().joined()
		}
	}
	
	override var keyEquivalent: String {
		didSet {
			_view.keyChar.stringValue = keyEquivalent.uppercased()
		}
	}
	
	internal func setBadge(_ value: String?, color: NSColor = .systemRed) {
		guard let view = view as? NSMenuBadgeItemView else {
			return
		}
		if let value = value {
			view.badge.isHidden = false
			view.badge.backgroundColor = color
			view.badge.stringValue 	   = value
		}else {
			view.badge.isHidden = true
		}
	}
}
