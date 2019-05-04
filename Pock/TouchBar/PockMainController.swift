//
//  PockMainController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation

/// Custom identifiers
extension NSTouchBar.CustomizationIdentifier {
    static let pockTouchBar = "PockTouchBar"
}
extension NSTouchBarItem.Identifier {
    static let pockSystemIcon = NSTouchBarItem.Identifier("Pock")
    static let dockView       = NSTouchBarItem.Identifier("Dock")
    static let escButton      = NSTouchBarItem.Identifier("Esc")
    static let controlCenter  = NSTouchBarItem.Identifier("ControlCenter")
    static let nowPlaying     = NSTouchBarItem.Identifier("NowPlaying")
    static let status         = NSTouchBarItem.Identifier("Status")
}

class PockMainController: PockTouchBarController {
    
    override var systemTrayItemIdentifier: NSTouchBarItem.Identifier? { return .pockSystemIcon }
    
    required init() {
        super.init()
        self.showControlStripIcon()
        self.registerForNotifications()
    }
    
    deinit {
        self.unregisterForNotifications()
    }
    
    override func awakeFromNib() {
        self.touchBar?.customizationIdentifier              = .pockTouchBar
        self.touchBar?.defaultItemIdentifiers               = [.escButton, .dockView]
        self.touchBar?.customizationAllowedItemIdentifiers  = [.escButton, .dockView, .controlCenter, .nowPlaying, .status]
        
        super.awakeFromNib()
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
            
        /// Esc button
        case .escButton:
            let widget = EscWidget(identifier: identifier)
            return widget
            
        /// Dock widget
        case .dockView:
            let widget = DockWidget(identifier: identifier)
            return widget
            
        /// ControlCenter widget
        case .controlCenter:
            let widget = ControlCenterWidget(identifier: identifier)
            return widget
            
        /// NowPlaying widget
        case .nowPlaying:
            let widget = NowPlayingWidget(identifier: identifier)
            return widget
            
        /// Status widget
        case .status:
            let widget = StatusWidget(identifier: identifier)
            return widget
        
        default:
            return nil
        
        }
    }
    
    /// Not in use right now.
    private func showControlStripIcon() {
        DFRSystemModalShowsCloseBoxWhenFrontMost(true)
        let item = NSCustomTouchBarItem(identifier: .pockSystemIcon)
        item.view = NSButton(image: #imageLiteral(resourceName: "pock-inner-icon"), target: self, action: #selector(present))
        NSTouchBarItem.addSystemTrayItem(item)
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
}
