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
                    PockHelper.default.installDefaultWidgets()
                }
            }
            let identifiers: [NSTouchBarItem.Identifier] = widgets.compactMap({ $0.identifier })
            self?.touchBar?.customizationIdentifier             = .pockTouchBar
            self?.touchBar?.customizationAllowedItemIdentifiers = identifiers
            self?.awakeFromNib()
			self?.checkForBlankTouchBar()
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
    
    override func present() {
        self.isVisible = true
        presentFromSystemTrayItem()
    }
    
    @objc private func presentFromSystemTrayItem() {
        let placement: Int64 = TouchBarHelper.isSystemControlStripVisible ? 0 : 1
        self.presentWithPlacement(placement: placement)
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
