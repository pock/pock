//
//  TouchBarController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class PockTouchBarController: NSObject {
    
    @IBOutlet weak var touchBar: NSTouchBar?
    
    override init() {
        super.init()
        self.showControlStripIcon()
        self.registerForNotifications()
    }
    
    private func registerForNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(reloadPock), name: .shouldReloadPock, object: nil)
    }
    
    @objc func reloadPock() {
        if #available (macOS 10.14, *) {
            NSTouchBar.dismissSystemModalTouchBar(touchBar)
        } else {
            NSTouchBar.dismissSystemModalFunctionBar(touchBar)
        }
        self.present()
    }
    
    @objc func present() {
        let placement: Int64 = defaults[.hideControlStrip] ? 1 : 0
        self.presentWithPlacement(placement: placement)
    }
    
    private func presentWithPlacement(placement: Int64) {
        if #available (macOS 10.14, *) {
            NSTouchBar.presentSystemModalTouchBar(touchBar, placement: placement, systemTrayItemIdentifier: .pockSystemIcon)
        } else {
            NSTouchBar.presentSystemModalFunctionBar(touchBar, systemTrayItemIdentifier: .pockSystemIcon)
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
