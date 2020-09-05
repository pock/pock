//
//  Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

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
