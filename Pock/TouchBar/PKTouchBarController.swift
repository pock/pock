//
//  TouchBarController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class PKTouchBarController: NSObject, NSTouchBarDelegate {
    
    @IBOutlet var touchBar: NSTouchBar?
    
    private(set) var isVisible: Bool = false
    
    weak var navController: PKTouchBarNavController?
    
    var systemTrayItem:           NSCustomTouchBarItem?      { return nil }
    var systemTrayItemIdentifier: NSTouchBarItem.Identifier? { return nil }
    
    override required init() { super.init() }
    
    class func load<T: PKTouchBarController>(_ type: T.Type = T.self) -> T {
        let controller = T()
        controller.reloadNib(type)
        return controller
    }
    
    private func reloadNib<T: PKTouchBarController>(_ type: T.Type = T.self) {
        Bundle.main.loadNibNamed(NSNib.Name(String(describing: type)), owner: self, topLevelObjects: nil)
        if touchBar == nil {
            touchBar = NSTouchBar()
            touchBar?.delegate = self
        }
        self.didLoad()
        self.showControlStripIcon()
    }
    
    func didLoad() {
        /// override in subclasses.
    }
    
    func showControlStripIcon() {
        DFRSystemModalShowsCloseBoxWhenFrontMost(false)
        guard systemTrayItem != nil else { return }
        NSTouchBarItem.removeSystemTrayItem(systemTrayItem!)
        NSTouchBarItem.addSystemTrayItem(systemTrayItem!)
    }
    
    @objc func toggle() {
        if self.isVisible {
            self.minimize()
        }else {
            self.present()
        }
    }
    
    @objc func dismiss() {
        if #available (macOS 10.14, *) {
            NSTouchBar.dismissSystemModalTouchBar(touchBar)
        } else {
            NSTouchBar.dismissSystemModalFunctionBar(touchBar)
        }
        self.isVisible = false
    }
    
    @objc func minimize() {
        if #available (macOS 10.14, *) {
            NSTouchBar.minimizeSystemModalTouchBar(touchBar)
        } else {
            NSTouchBar.minimizeSystemModalFunctionBar(touchBar)
        }
        self.isVisible = false
    }
    
    @objc func present() {
        self.reloadNib()
        let placement: Int64 = Defaults[.hideControlStrip] ? 1 : 0
        self.presentWithPlacement(placement: placement)
        self.isVisible = true
    }
    
    private func presentWithPlacement(placement: Int64) {
        if #available (macOS 10.14, *) {
            NSTouchBar.presentSystemModalTouchBar(touchBar, placement: placement, systemTrayItemIdentifier: systemTrayItemIdentifier)
        } else {
            NSTouchBar.presentSystemModalFunctionBar(touchBar, placement: placement, systemTrayItemIdentifier: systemTrayItemIdentifier)
        }
    }
    
}

extension PKTouchBarController {
    
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
        NSApp.touchBar = nil
        self.removeCustomizationObservers()
        self.present()
    }
    
}
