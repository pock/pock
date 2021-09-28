//
//  NSImage+Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 09/03/21.
//

import Foundation
import AppKit

extension NSImage.Name {
	static var pockInnerIcon = NSImage.Name("pock-inner-icon")
	static var widgetIcon = NSImage.Name("widget-icon")
}

extension NSImage {
	/// Returns an NSImage snapshot of the passed view in 2x resolution.
	convenience init?(frame: NSRect, view: NSView) {
		guard let bitmapRep = view.bitmapImageRepForCachingDisplay(in: frame) else {
			return nil
		}
		self.init()
		view.cacheDisplay(in: frame, to: bitmapRep)
		addRepresentation(bitmapRep)
		bitmapRep.size = frame.size
	}
}
