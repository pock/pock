//
//  DockItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class DockItem: Equatable {
    static func == (lhs: DockItem, rhs: DockItem) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier || lhs.path == rhs.path
    }
    
    var index:              Int
    let bundleIdentifier:   String?
    var name:               String?
    let path:               URL?
    var icon:               NSImage?
    var badge:              String?
    var pid_t:              pid_t = 0
    var isLaunching:        Bool  = false
    var isFrontmost:        Bool { return NSWorkspace.shared.frontmostApplication?.bundleIdentifier == self.bundleIdentifier }
    
    var hasBadge: Bool {
        return badge != nil && badge?.count ?? 0 > 0
    }
    
    var isRunning: Bool {
        return pid_t != 0
    }
    
    init(_ index: Int, _ bundleIdentifier: String?, name: String?, path: URL?, icon: NSImage?, pid_t: pid_t, launching: Bool = false) {
        self.index              = index
        self.bundleIdentifier   = bundleIdentifier
        self.name               = name
        self.path               = path
        self.icon               = icon
        self.pid_t              = pid_t
        self.isLaunching        = launching
    }
}
