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
    var isLaunchpad: Bool {
        get {
            return bundleIdentifier == "com.apple.launchpad.launcher"
        }
    }
    var isFileOrDirectory: Bool {
        get {
            return bundleIdentifier.contains("file://")
        }
    }
    var isRunning: Bool {
        get {
            return PockUtilities.runningAppsIdentifiers.contains(where: { $0 == bundleIdentifier })
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
