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
    static let pockTouchBar = NSTouchBar.CustomizationIdentifier("PockTouchBar")
}
extension NSTouchBarItem.Identifier {
    static let pockSystemIcon = NSTouchBarItem.Identifier("Pock")
    static let dockView       = NSTouchBarItem.Identifier("Dock")
    static let escButton      = NSTouchBarItem.Identifier("Esc")
}

class PockMainController: PockTouchBarController, NSTouchBarDelegate {
    
    private var items: [String: PockWidget] = [:]
    
    override func awakeFromNib() {
        self.touchBar?.customizationIdentifier              = .pockTouchBar
        self.touchBar?.defaultItemIdentifiers               = [.escButton, .dockView]
        self.touchBar?.customizationAllowedItemIdentifiers  = [.escButton, .dockView]
        
        super.awakeFromNib()
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if let item = items[identifier.rawValue] { return item }
        switch identifier {
            
        /// Esc button
        case .escButton:
            let widget = EscWidget(identifier: identifier)
            items[identifier.rawValue] = widget
            return widget
            
        /// Dock widget
        case .dockView:
            let widget = DockWidget(identifier: identifier)
            items[identifier.rawValue] = widget
            return widget
        
        default:
            return nil
        
        }
    }
}
