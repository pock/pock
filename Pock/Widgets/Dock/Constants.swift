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
    static let dockItemSize:            NSSize  = NSSize(width: 50, height: 30)
    static let dockItemDotSize:         NSSize  = NSSize(width: 4,  height: 4)
    static let dockItemBadgeHeight:     NSSize  = NSSize(width: 10, height: 10)
    static let dockItemBounceThreshold: CGFloat = 10
    /// Keys
    static let kDockItemView:    NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "kDockItemView")
    static let kBounceAnimation: String = "kBounceAnimation"
}
