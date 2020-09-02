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

class PockMainController: PKTouchBarController {
    
    private var items: [NSTouchBarItem.Identifier: NSTouchBarItem] = [:]
    
    private var systemTrayItem: NSCustomTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: .pockSystemIcon)
        item.view = NSButton(image: #imageLiteral(resourceName: "pock-inner-icon"), target: self, action: #selector(presentFromSystemTrayItem))
        return item
    }
    
    private var systemTrayItemIdentifier: NSTouchBarItem.Identifier? { return .pockSystemIcon }
    
    deinit {
        items.removeAll()
        WidgetsDispatcher.default.clearLoadedWidgets()
        #if DEBUG
            print("[PockMainController]: Deinit Pock main controller")
        #endif
    }
    
    override func reloadNib<T>(_ type: T.Type = T.self) where T : PKTouchBarController {
        super.reloadNib(type)
        self.showControlStripIcon()
    }
    
    override func didLoad() {
        WidgetsDispatcher.default.loadInstalledWidget() { [weak self] identifiers in
            self?.touchBar?.customizationIdentifier = .pockTouchBar
            self?.touchBar?.customizationAllowedItemIdentifiers.append(contentsOf: identifiers)
            self?.awakeFromNib()
        }
    }
    
    override func present() {
        presentFromSystemTrayItem()
    }
    
    @objc private func presentFromSystemTrayItem() {
        let placement: Int64 = TouchBarHelper.isSystemControlStripVisible ? 0 : 1
        self.presentWithPlacement(placement: placement)
    }
    
    private func showControlStripIcon() {
        DFRSystemModalShowsCloseBoxWhenFrontMost(false)
        guard systemTrayItem != nil else { return }
        NSTouchBarItem.removeSystemTrayItem(systemTrayItem!)
        NSTouchBarItem.addSystemTrayItem(systemTrayItem!)
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
        guard let widget: PKWidget = WidgetsDispatcher.default.loadedWidgets[identifier]?.init() else {
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
        self.dismiss()
    }
    
    @objc private func didExitCustomization(_ sender: Any?) {
        TouchBarHelper.dismissFromTop(NSApp.touchBar)
        self.removeCustomizationObservers()
        self.present()
    }
    
}
