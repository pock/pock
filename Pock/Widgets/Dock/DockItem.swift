//
//  DockItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class DockItem {
    let bundleIdentifier:   String
    let name:               String
    let path:               URL
    let icon:               NSImage
    let pid_t:              pid_t
    var isLaunching:        Bool
    init(_ bundleIdentifier: String, name: String, path: URL, icon: NSImage, pid_t: pid_t, launching: Bool) {
        self.bundleIdentifier   = bundleIdentifier
        self.name               = name
        self.path               = path
        self.icon               = icon
        self.pid_t              = pid_t
        self.isLaunching        = launching
    }
}
