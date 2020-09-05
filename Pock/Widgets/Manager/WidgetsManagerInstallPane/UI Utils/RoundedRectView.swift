//
//  RoundedRectView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/09/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import AppKit

@IBDesignable class RoundedRectView: NSView {
    
    // MARK: Inspectables
    @IBInspectable public var color:  NSColor = NSColor.systemGray.withAlphaComponent(0.3) {
        didSet {
            updateStyle()
        }
    }
    @IBInspectable public var radius: CGFloat = 4 {
        didSet {
            updateStyle()
        }
    }
    
    private func updateStyle() {
        setNeedsDisplay(bounds)
        displayIfNeeded()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: NSInsetRect(bounds, radius, radius), xRadius: radius, yRadius: radius)
        color.set()
        path.fill()
    }
    
}
