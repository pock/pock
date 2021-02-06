//
//  NSMenuBadgeItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 22/01/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation

@IBDesignable
internal class NSMenuBadgeItemView: NSMenuItemCustomView {

	@IBOutlet internal private(set) weak var badge: NSTextField!
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		self.badge.layer?.cornerRadius = self.badge.frame.height / 2
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		badge.isHidden = true
	}
}

internal class NSMenuBadgeItem: NSMenuItem {
	
	private var _view: NSMenuBadgeItemView? {
		return view as? NSMenuBadgeItemView
	}
	
	override var title: String {
		didSet {
			_view?.mainLabel?.stringValue = title
		}
	}
	
	override var keyEquivalentModifierMask: NSEvent.ModifierFlags {
		didSet {
			_view?.keyModifier.stringValue = keyEquivalentModifierMask.keyEquivalentStrings().joined()
		}
	}
	
	override var keyEquivalent: String {
		didSet {
			_view?.keyChar.stringValue = keyEquivalent.uppercased()
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
