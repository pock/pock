//
//  PKWidgetViewController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 11/03/21.
//

import AppKit
import PockKit

internal class PKWidgetViewController: NSViewController {
	
	/// Data
	private weak var widgetItem: PKWidgetTouchBarItem!
	private var widgetIdentifier: String!
	
	/// Initialiser
	convenience init(item: PKWidgetTouchBarItem) {
		self.init()
		widgetIdentifier = item.identifier.rawValue
		widgetItem = item
		view = item.widget!.view
	}
	
	deinit {
		Roger.debug("[\(widgetIdentifier ?? "Unknown")][viewController] - deinit")
	}
	
	/// Overrides
	override func viewWillAppear() {
		super.viewWillAppear()
		widgetItem?.widget?.viewWillAppear?()
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		widgetItem?.widget?.viewDidAppear?()
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		widgetItem?.widget?.viewWillDisappear?()
	}
	
	override func viewDidDisappear() {
		super.viewDidDisappear()
		widgetItem?.widget?.viewDidDisappear?()
	}
	
}
