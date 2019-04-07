//
//  Constants.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class Constants {
    /// Known identifiers
    static let kFinderIdentifier: String = "com.apple.finder"
    /// Known paths
    static let dockPlist = NSHomeDirectory().appending("/Library/Preferences/com.apple.dock.plist")
    static let trashPath = NSHomeDirectory().appending("/.Trash")
    /// UI
    static let dockItemSize:            NSSize  = NSSize(width: 40, height: 30)
    static let dockItemIconSize:        NSSize  = NSSize(width: 24, height: 24)
    static let dockItemDotSize:         NSSize  = NSSize(width: 3,  height: 3)
    static let dockItemBadgeSize:       NSSize  = NSSize(width: 10, height: 10)
    static let dockItemCornerRadius:    CGFloat = 6
    static let dockItemBounceThreshold: CGFloat = 10
    /// Keys
    static let kDockItemView:    NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "kDockItemView")
    static let kBounceAnimation: String = "kBounceAnimation"
}
