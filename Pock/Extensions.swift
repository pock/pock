//
//  Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

extension Notification.Name {
	static let screenIsLocked 	= Notification.Name("com.apple.screenIsLocked")
	static let screenIsUnlocked = Notification.Name("com.apple.screenIsUnlocked")
}

extension String {
    func truncate(length: Int, trailing: String = "…") -> String {
        return self.count > length ? String(self.prefix(length)) + trailing : self
    }
}

extension NSImage {
    func resize(w: Int, h: Int, color: NSColor = .white) -> NSImage {
        let destSize = NSMakeSize(CGFloat(w), CGFloat(h))
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, size.width, size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.tiffRepresentation!)!.tint(color: color)
    }
    func tint(color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}

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

// MARK: Async / Background
public func async(after: TimeInterval = 0, _ block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + after, execute: { [block] in
        block()
    })
}
public func async(after: TimeInterval = 0, _ block: @escaping () throws -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + after, execute: { [block] in
        do {
            try block()
        } catch {
            NSLog("[async(after: \(after)]: Invalid block: \(error.localizedDescription)")
        }
    })
}
public func background(qos: DispatchQoS.QoSClass = .background, after: TimeInterval = 0, _ block: @escaping () -> Void) {
    DispatchQueue.global(qos: qos).asyncAfter(deadline: .now() + after, execute: { [block] in
        block()
    })
}
public func background(qos: DispatchQoS.QoSClass = .background, after: TimeInterval = 0, _ block: @escaping () throws -> Void) {
    DispatchQueue.global(qos: qos).asyncAfter(deadline: .now() + after, execute: { [block] in
        do {
            try block()
        } catch {
            NSLog("[background(qos: \(qos), after: \(after)]: Invalid block: \(error.localizedDescription)")
        }
    })
}
