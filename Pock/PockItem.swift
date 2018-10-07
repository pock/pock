//
//  PockItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 01/08/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation

public class PockItem: NSObject {
    var label: String!, bundleIdentifier: String!, icon: NSImage!
    var isRunning: Bool {
        get {
            return PockUtilities.runningAppsIdentifiers.contains(self.bundleIdentifier)
        }
    }
    var isFrontmostApplication: Bool {
        get {
            return self.bundleIdentifier == PockUtilities.frontmostApplicationIdentifier
        }
    }
    var hasBadge: Bool {
        return PockDockHelper.sharedInstance().getBadgeCountForItem(withName: label) != nil
    }
    convenience init(label: String, bundleIdentifier: String, icon: NSImage) {
        self.init()
        self.label = label
        self.bundleIdentifier = bundleIdentifier
        self.icon = icon
    }
}
