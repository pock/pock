//
//  TouchBarController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class PockTouchBarController: NSObject, NSTouchBarDelegate {
    
    @IBOutlet weak var touchBar: NSTouchBar?
    
    override init() {
        super.init()
        self.showControlStripIcon()
        self.registerForNotifications()
    }
    
    deinit {
        self.unregisterForNotifications()
    }
    
    private func unregisterForNotifications() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    private func registerForNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(reloadPock), name: .shouldReloadPock, object: nil)
    }
    
    @objc func reloadPock() {
        self.dismiss()
        self.present()
    }
    
    @objc func dismiss() {
        if #available (macOS 10.14, *) {
            NSTouchBar.dismissSystemModalTouchBar(touchBar)
        } else {
            NSTouchBar.dismissSystemModalFunctionBar(touchBar)
        }
    }
    
    @objc func present() {
        let placement: Int64 = defaults[.hideControlStrip] ? 1 : 0
        self.presentWithPlacement(placement: placement)
    }
    
    private func presentWithPlacement(placement: Int64) {
        if #available (macOS 10.14, *) {
            NSTouchBar.presentSystemModalTouchBar(touchBar, placement: placement, systemTrayItemIdentifier: .pockSystemIcon)
        } else {
            NSTouchBar.presentSystemModalFunctionBar(touchBar, placement: placement, systemTrayItemIdentifier: .pockSystemIcon)
        }
    }
    
    /// Not in use right now.
    private func showControlStripIcon() {
        DFRSystemModalShowsCloseBoxWhenFrontMost(true)
        let item = NSCustomTouchBarItem(identifier: .pockSystemIcon)
        item.view = NSButton(image: #imageLiteral(resourceName: "pock-inner-icon"), target: self, action: #selector(present))
        NSTouchBarItem.addSystemTrayItem(item)
    }
    
}

extension PockTouchBarController {
    
    func openCustomization() {
        NSApp.touchBar = self.touchBar
        self.addCustomizationObservers()
        self.perform(#selector(delayedOpenCustomization), with: nil, afterDelay: 0)
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
        NSApp.toggleTouchBarCustomizationPalette(self)
    }
    
    @objc private func willEnterCustomization(_ sender: Any?) {
        self.dismiss()
    }
    
    @objc private func didExitCustomization(_ sender: Any?) {
        NSApp.touchBar = nil
        self.removeCustomizationObservers()
        self.present()
    }
    
}
