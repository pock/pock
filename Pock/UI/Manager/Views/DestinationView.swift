//
//  DestinationView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/05/21.
//

import AppKit

internal class DestinationView: NSView {
	
	// MARK: Data
	
	private let radius: CGFloat = 8
	
	internal var completion: ((URL) -> Void)?
	
	/// Allowed extensions, separated by commas (`,`) without spaces
	@IBInspectable internal var allowedExtension: String!
	
	private var allowedExtensions: [String] {
		return allowedExtension.split(separator: ",").compactMap({ String($0) })
	}
	
	/// Default background color used for normal state
	@IBInspectable internal var defaultColor: NSColor = NSColor.windowBackgroundColor.withAlphaComponent(0.275)
	
	/// Background color used for dragging state
	@IBInspectable internal var draggingColor: NSColor = NSColor.systemBlue.withAlphaComponent(0.275)
	
	private lazy var currentColor = defaultColor {
		didSet {
			setNeedsDisplay(bounds)
			displayIfNeeded()
		}
	}
	
	// MARK: Initialiser
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		registerForDraggedTypes([.URL, .fileURL])
	}
	
	// MARK: Overrides
	
	override func draw(_ dirtyRect: NSRect) {
		let path = NSBezierPath(roundedRect: bounds.insetBy(dx: radius, dy: radius), xRadius: radius, yRadius: radius)
		currentColor.set()
		path.fill()
	}
	
	// MARK: Helpers
	
	private func checkExtension(for draggingInfo: NSDraggingInfo) -> Bool {
		guard let list = draggingInfo.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
			  let path = list.firstObject as? String else {
			return false
		}
		let draggedFileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
		return allowedExtensions.map({ $0.lowercased() }).contains(draggedFileExtension)
	}
	
	// MARK: Drag&Dropp stuff
	
	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		guard checkExtension(for: sender) else {
			return NSDragOperation()
		}
		currentColor = draggingColor
		return .copy
	}
	
	override func draggingExited(_ sender: NSDraggingInfo?) {
		currentColor = defaultColor
	}
	
	override func draggingEnded(_ sender: NSDraggingInfo) {
		currentColor = defaultColor
	}
	
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
			  let path = pasteboard.firstObject as? String,
			  let url = URL(string: path) else {
			return false
		}
		completion?(url)
		return true
	}
	
}
