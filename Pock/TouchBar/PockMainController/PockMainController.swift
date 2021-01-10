//
//  PockMainController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import PockKit

/// Custom identifiers
extension NSTouchBar.CustomizationIdentifier {
    static let pockTouchBar = "PockTouchBar"
}

extension NSTouchBarItem.Identifier {
    static let pockSystemIcon = NSTouchBarItem.Identifier("Pock")
}

class PockMainController: PKTouchBarMouseController {
    
    // MARK: Data
    private var items: [NSTouchBarItem.Identifier: NSTouchBarItem] = [:]
    private var systemTrayItemIdentifier: NSTouchBarItem.Identifier? { return .pockSystemIcon }
    
	// MARK: Mouse Support
	private var mouseDelegates: [PKScreenEdgeMouseDelegate] = []
	private var touchBarView: NSView {
		guard let views = NSFunctionRow._topLevelViews() as? [NSView], let view = views.last else {
			fatalError("Touch Bar is not available.")
		}
		return view
	}
	public override var visibleRectWidth: CGFloat {
		get { return touchBarView.visibleRect.width } set { /**/ }
	}
	public override var parentView: NSView! {
		get { return touchBarView } set { /**/ }
	}
	
    deinit {
        items.removeAll()
        WidgetsDispatcher.default.clearLoadedWidgets()
        #if DEBUG
            print("[PockMainController]: Deinit Pock main controller")
        #endif
    }
    
    override func didLoad() {
		super.didLoad()
        WidgetsDispatcher.default.loadInstalledWidget() { [weak self] widgets in
            if widgets.isEmpty && PockHelper.didAskToInstallDefaultWidgets == false {
                async(after: 1) {
					PockHelper.default.installDefaultWidgets { [widgets] in
						self?.load(widgets: widgets)
					}
                }
				return
            }
			self?.load(widgets: widgets)
        }
    }
	
	private func load(widgets: [PKWidget]) {
		let identifiers: [NSTouchBarItem.Identifier] = widgets.compactMap({ $0.identifier })
		self.touchBar?.customizationIdentifier             = .pockTouchBar
		self.touchBar?.customizationAllowedItemIdentifiers = identifiers
		self.awakeFromNib()
		self.checkForBlankTouchBar()
		mouseDelegates.removeAll()
		if PockHelper.mouseSupportIsEnabled {
			for widget in widgets.compactMap({ $0 as? PKScreenEdgeMouseDelegate }) {
				mouseDelegates.append(widget)
			}
		}
	}
	
	private func checkForBlankTouchBar() {
		guard PockHelper.allowBlankTouchBar == false else {
			return
		}
		async(after: 1) { [weak self] in
			if self?.items.isEmpty == true {
				PockHelper.default.openProcessControllerForEmptyWidgets()
			}
		}
	}
    
	override func dismiss() {
		TouchBarHelper.setPresentationMode(to: .preferred)
		super.dismiss()
	}
	
    override func present() {
		/// Keep reference to user preferred presentation mode
		TouchBarHelper.setPresentationMode(to: .app)
        self.isVisible = true
		self.presentWithPlacement(placement: 1)
    }
    
    private func presentWithPlacement(placement: Int64) {
        if #available (macOS 10.14, *) {
            NSTouchBar.presentSystemModalTouchBar(touchBar, placement: placement, systemTrayItemIdentifier: systemTrayItemIdentifier)
        } else {
            NSTouchBar.presentSystemModalFunctionBar(touchBar, placement: placement, systemTrayItemIdentifier: systemTrayItemIdentifier)
        }
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if let item = items[identifier] {
            return item
        }
        guard let widget: PKWidget = WidgetsDispatcher.default.loadedWidgets.first(where: { $0.identifier == identifier }) else {
            return nil
        }
        let item = PKWidgetTouchBarItem(widget: widget)
        items[identifier] = item
        return item
    }
	
	// MARK: Mouse Overrides
	override func reloadScreenEdgeController() {
		if PockHelper.mouseSupportIsEnabled {
			let color: NSColor = PockHelper.showMouseTrackingArea ? .black : .clear
			self.edgeController = PKScreenEdgeController(mouseDelegate: self, parentView: parentView, barColor: color)
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
	
	override func screenEdgeController(_ controller: PKScreenEdgeController, mouseScrollWithDelta delta: CGFloat, atLocation location: NSPoint, in view: NSView) {
		super.screenEdgeController(controller, mouseScrollWithDelta: delta, atLocation: location, in: view)
		mouseDelegates.forEach({
			$0.screenEdgeController?(controller, mouseScrollWithDelta: delta, atLocation: location, in: view)
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

extension PockMainController {
    
    func openCustomization() {
        NSApp.touchBar = self.touchBar
        self.addCustomizationObservers()
        self.perform(#selector(delayedOpenCustomization), with: nil, afterDelay: 0.3)
    }
    
    private func addCustomizationObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterCustomization(_:)),
                                               name: NSNotification.Name("NSTouchBarWillEnterCustomization"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didExitCustomization(_:)),
                                               name: NSNotification.Name("NSTouchBarDidExitCustomization"),
                                               object: nil)
    }
    
    private func removeCustomizationObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name("NSTouchBarWillEnterCustomization"),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name("NSTouchBarDidExitCustomization"),
                                                  object: nil)
    }
    
    @objc private func delayedOpenCustomization() {
        NSApp.toggleTouchBarCustomizationPalette(nil)
    }
    
    @objc private func willEnterCustomization(_ sender: Any?) {
        self.minimize()
    }
    
    @objc private func didExitCustomization(_ sender: Any?) {
        TouchBarHelper.dismissFromTop(NSApp.touchBar)
        self.removeCustomizationObservers()
        self.present()
		self.checkForBlankTouchBar()
    }
    
}
