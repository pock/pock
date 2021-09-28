//
//  NSView+Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 07/05/21.
//

import AppKit

extension NSView {
	func findViews<T: NSView>(subclassOf: T.Type = T.self) -> [T] {
		return recursiveSubviews.compactMap { $0 as? T }
	}
	func findViews(subclassOf name: String) -> [NSView] {
		return recursiveSubviews.compactMap {
			let viewClassName = String(describing: type(of: $0))
			return name == viewClassName ? $0 : nil
		}
	}
	var recursiveSubviews: [NSView] {
		return subviews + subviews.flatMap { $0.recursiveSubviews }
	}
	func superview<T: NSView>(subclassOf type: T.Type = T.self) -> T? {
		guard let view = superview else {
			return nil
		}
		return view as? T ?? view.superview(subclassOf: type)
	}
	func superview(subclassOf name: String = "NSView") -> NSView? {
		guard let view = superview else {
			return nil
		}
		let viewClassName = String(describing: type(of: view))
		return name == viewClassName ? view : view.superview(subclassOf: name)
	}
	func subview<T: NSView>(at location: NSPoint?, in parentView: NSView? = nil, of type: T.Type = T.self) -> T? {
		guard let location = location else {
			return nil
		}
		let loc = NSPoint(x: location.x, y: 12)
		let views = self.findViews(subclassOf: type)
		return views.first(where: { $0.superview?.convert($0.frame, to: parentView ?? self).contains(loc) == true })
	}
	func subview(in view: NSView?, at location: NSPoint?, of type: String) -> NSView? {
		guard let view = view, let location = location else {
			return nil
		}
		let loc = NSPoint(x: location.x, y: 12)
		let views = self.findViews(subclassOf: type)
		return views.first(where: { $0.superview?.convert($0.frame, to: view).contains(loc) == true })
	}
}
