//
//  PockTouchBarController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation
import AppCenterAnalytics
import PockKit

/// Customization identifier
extension NSTouchBar.CustomizationIdentifier {
	static let pockTouchBarController = "PockTouchBarController"
}

/// Pock (main Touch Bar controller)
internal class PockTouchBarController: PKTouchBarMouseController {

	/// Data
	private(set) var widgets: [NSTouchBarItem.Identifier: PKWidgetInfo] = [:]
	private(set) var cachedItems: [NSTouchBarItem.Identifier: NSTouchBarItem] = [:]
	
	private var currentItems: [NSTouchBarItem.Identifier] {
		return touchBar?.itemIdentifiers ?? []
	}
	private var emptyTouchBarController: EmptyTouchBarController?
	
	internal var allowedCustomizationIdentifiers: [NSTouchBarItem.Identifier] {
		return Array(widgets.keys) + [.flexibleSpace]
	}
	
	// MARK: Mouse Support
	private var touchBarView: NSView? {
		guard let views = NSFunctionRow._topLevelViews() as? [NSView], let view = views.last else {
            Roger.debug("Touch Bar is not available.")
            return nil
		}
		return view
	}
	public override var parentView: NSView? {
		get {
			return touchBarView
		} set {
			super.parentView = newValue
		}
	}
	
	// MARK: Overrides
	override func didLoad() {
		super.didLoad()
		Roger.debug("[PockTouchBarController] Loaded.")
	}
	
	deinit {
		Roger.info("Deinit")
		flushWidgetItems()
		emptyTouchBarController = nil
		touchBar = nil
	}

	override func present() {
        guard AppController.shared.isLocked == false, isVisible == false else {
			return
		}
		for widget in WidgetsLoader.loadedWidgets {
			widgets[NSTouchBarItem.Identifier(widget.bundleIdentifier)] = widget
		}
		let placement: Int64
		let presentationMode: PresentationMode
		switch Preferences[.layoutStyle] as LayoutStyle {
		case .withControlStrip:
			placement = 0
			presentationMode = .appWithControlStrip
		case .fullWidth:
			placement = 1
			presentationMode = .app
		}
		isVisible = true
		if #available (macOS 10.14, *) {
			NSTouchBar.presentSystemModalTouchBar(touchBar, placement: placement, systemTrayItemIdentifier: nil)
		} else {
			NSTouchBar.presentSystemModalFunctionBar(touchBar, placement: placement, systemTrayItemIdentifier: nil)
		}
		TouchBarHelper.setPresentationMode(to: presentationMode)
		checkForBlankTouchBar()
	}
	
	override func minimize() {
		emptyTouchBarController?.dismiss()
		super.minimize()
	}
	
	override func dismiss() {
		emptyTouchBarController?.dismiss()
		guard isVisible else {
			return
		}
		TouchBarHelper.setPresentationMode(to: Preferences[.userDefinedPresentationMode] as PresentationMode)
		super.dismiss()
	}
	
	private func flushWidgetItems() {
		cachedItems.removeAll()
		widgets.removeAll()
	}

	/// Setup Touch Bar
	override func makeTouchBar() -> NSTouchBar? {
		let touchBar = NSTouchBar()
		touchBar.delegate = self
		touchBar.customizationIdentifier = .pockTouchBarController
		touchBar.customizationAllowedItemIdentifiers = allowedCustomizationIdentifiers
		for key in widgets.keys {
			Roger.info("[\(key.rawValue)] - Allowed for customization")
		}
		return touchBar
	}

	/// Make Touch Bar item for given identifier
	func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
		if let item = cachedItems[identifier] {
			Roger.info("[\(identifier.rawValue)][item] - cached")
			return item
		}
		guard let widget = widgets[identifier] else {
			Roger.error("Can't find `NSTouchBarItem` for given identifier: `\(identifier)`")
			return nil
		}
		Roger.info("[\(identifier.rawValue)][item] - initializes")
		let item = PKWidgetTouchBarItem(widget: widget)
		cachedItems[identifier] = item
		return item
	}
	
	// MARK: Blank Touch Bar
	private func checkForBlankTouchBar() {
		emptyTouchBarController?.dismiss()
		emptyTouchBarController = nil
		guard Preferences[.allowBlankTouchBar] == false else {
			return
		}
		async(after: 0.225) { [weak self] in
			guard let self = self else {
				return
			}
			if self.widgets.isEmpty {
				self.emptyTouchBarController = AppController.shared.showEmptyTouchBarController(with: .installDefault)
			} else {
				if self.currentItems.isEmpty {
					self.emptyTouchBarController = AppController.shared.showEmptyTouchBarController(with: .empty)
				}
			}
		}
	}
	
	// MARK: Mouse delegates
	
	private var mouseDelegates: [PKScreenEdgeMouseDelegate] {
		return cachedItems.values.compactMap({ ($0 as? PKWidgetTouchBarItem)?.widget as? PKScreenEdgeMouseDelegate })
	}
	
	// MARK: Mouse Overrides
	override func reloadScreenEdgeController() {
		if Preferences[.mouseSupportEnabled], let parentView = parentView {
			let color: NSColor = Preferences[.showTrackingArea] ? .systemBlue : .clear
			self.edgeController = PKScreenEdgeController(mouseDelegate: self, parentView: parentView, barColor: color)
		} else {
			self.edgeController?.tearDown(invalidate: true)
			self.edgeController = nil
		}
	}
	
	override func screenEdgeController(_ controller: PKScreenEdgeController, mouseEnteredAtLocation location: NSPoint, in view: NSView) {
		super.screenEdgeController(controller, mouseEnteredAtLocation: location, in: view)
		mouseDelegates.forEach({
			$0.screenEdgeController(controller, mouseEnteredAtLocation: location, in: view)
		})
	}
	
	override func screenEdgeController(_ controller: PKScreenEdgeController, mouseMovedAtLocation location: NSPoint, in view: NSView) {
		super.screenEdgeController(controller, mouseMovedAtLocation: location, in: view)
		mouseDelegates.forEach({
			$0.screenEdgeController(controller, mouseMovedAtLocation: location, in: view)
		})
	}
    
    private func screenEdgeController(_ controller: PKScreenEdgeController, mouseScrollWithDelta delta: CGFloat, atLocation location: NSPoint, in view: NSView, event: NSEvent) {
        mouseDelegates.forEach({
            if $0.screenEdgeController?(controller, mouseScrollWithDelta: delta, atLocation: location, in: view) == nil {
                $0.screenEdgeController?(controller, mouseScrollWithDelta: delta, atLocation: location, in: view)
            }
        })
    }
	
	override func screenEdgeController(_ controller: PKScreenEdgeController, mouseClickAtLocation location: NSPoint, in view: NSView) {
		super.screenEdgeController(controller, mouseClickAtLocation: location, in: view)
		mouseDelegates.forEach({
			$0.screenEdgeController(controller, mouseClickAtLocation: location, in: view)
		})
	}
	
	override func screenEdgeController(_ controller: PKScreenEdgeController, mouseExitedAtLocation location: NSPoint, in view: NSView) {
		super.screenEdgeController(controller, mouseExitedAtLocation: location, in: view)
		mouseDelegates.forEach({
			$0.screenEdgeController(controller, mouseExitedAtLocation: location, in: view)
		})
	}
	
	// MARK: Dragging Overrides
	override func screenEdgeController(_ controller: PKScreenEdgeController, draggingEntered info: NSDraggingInfo, filepath: String, in view: NSView) -> NSDragOperation {
		var returnable: NSDragOperation?
		for delegate in mouseDelegates {
			guard let operation = delegate.screenEdgeController?(controller, draggingEntered: info, filepath: filepath, in: view) else {
				continue
			}
			returnable = operation
			self.showDraggingInfo(info, filepath: filepath)
			break
		}
		return returnable ?? super.screenEdgeController(controller, draggingEntered: info, filepath: filepath, in: view)
	}
	
	override func screenEdgeController(_ controller: PKScreenEdgeController, draggingUpdated info: NSDraggingInfo, filepath: String, in view: NSView) -> NSDragOperation {
		var returnable: NSDragOperation?
		for delegate in mouseDelegates {
			guard let operation = delegate.screenEdgeController?(controller, draggingUpdated: info, filepath: filepath, in: view) else {
				continue
			}
			returnable = operation
			self.updateCursorLocation(info.draggingLocation)
			self.updateDraggingInfoLocation(info.draggingLocation)
			break
		}
		return returnable ?? super.screenEdgeController(controller, draggingUpdated: info, filepath: filepath, in: view)
	}
	
	override func screenEdgeController(_ controller: PKScreenEdgeController, performDragOperation info: NSDraggingInfo, filepath: String, in view: NSView) -> Bool {
		var returnable: Bool?
		for delegate in mouseDelegates {
			guard let operation = delegate.screenEdgeController?(controller, performDragOperation: info, filepath: filepath, in: view) else {
				continue
			}
			returnable = operation
			break
		}
		return returnable ?? super.screenEdgeController(controller, performDragOperation: info, filepath: filepath, in: view)
	}
	
	override func screenEdgeController(_ controller: PKScreenEdgeController, draggingEnded info: NSDraggingInfo, in view: NSView) {
		super.screenEdgeController(controller, draggingEnded: info, in: view)
		mouseDelegates.forEach({
			$0.screenEdgeController?(controller, draggingEnded: info, in: view)
		})
	}

}
