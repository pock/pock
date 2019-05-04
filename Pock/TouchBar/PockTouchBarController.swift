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
    
    @IBOutlet var touchBar: NSTouchBar?
    
    var systemTrayItemIdentifier: NSTouchBarItem.Identifier? { return nil }
    
    override required init() { super.init() }
    
    class func load<T: PockTouchBarController>(_ type: T.Type = T.self) -> T {
        let controller = T()
        Bundle.main.loadNibNamed(NSNib.Name(String(describing: self)), owner: controller, topLevelObjects: nil)
        return controller
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
            NSTouchBar.presentSystemModalTouchBar(touchBar, placement: placement, systemTrayItemIdentifier: systemTrayItemIdentifier)
        } else {
            NSTouchBar.presentSystemModalFunctionBar(touchBar, placement: placement, systemTrayItemIdentifier: systemTrayItemIdentifier)
        }
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
