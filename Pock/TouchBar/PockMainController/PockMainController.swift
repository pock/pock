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
    }
    
    deinit {
        if !isProd { print("[PockMainController]: Deinit Pock main controller") }
    }
    
    override func awakeFromNib() {
        self.touchBar?.customizationIdentifier              = .pockTouchBar
        self.touchBar?.defaultItemIdentifiers               = [.escButton, .dockView]
        self.touchBar?.customizationAllowedItemIdentifiers  = [.escButton, .dockView, .controlCenter, .nowPlaying, .status]
        super.awakeFromNib()
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        var widget: PockWidget?
        switch identifier {
        /// Esc button
        case .escButton:
            widget = EscWidget(identifier: identifier)
        /// Dock widget
        case .dockView:
            widget = DockWidget(identifier: identifier)
        /// ControlCenter widget
        case .controlCenter:
            widget = ControlCenterWidget(identifier: identifier)
        /// NowPlaying widget
        case .nowPlaying:
            widget = NowPlayingWidget(identifier: identifier)
        /// Status widget
        case .status:
            widget = StatusWidget(identifier: identifier)
        default:
            return nil
        }
        return widget
    }
    
    /// Not in use right now.
    private func showControlStripIcon() {
        /* DFRSystemModalShowsCloseBoxWhenFrontMost(true)
        weak var item = NSCustomTouchBarItem(identifier: .pockSystemIcon)
        item.view = NSButton(image: #imageLiteral(resourceName: "pock-inner-icon"), target: self, action: #selector(present))
        NSTouchBarItem.addSystemTrayItem(item) */
    }
    
}
