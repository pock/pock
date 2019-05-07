//
//  DockFolderItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class DockFolderItem: Equatable {
    
    var index:         Int
    let name:          String?
    let detail:        String?
    let path:          URL?
    let icon:          NSImage?
    var isDirectory:   Bool = false
    var isApplication: Bool = false
    
    init(_ index: Int, name: String?, detail: String?, path: URL?, icon: NSImage?, isDirectory: Bool? = nil, isApplication: Bool? = nil) {
        self.index  = index
        self.name   = name?.hasSuffix(".app") ?? false ? name?.replacingOccurrences(of: ".app", with: "") : name
        self.detail = detail
        self.path   = path
        self.icon   = icon
        self.isDirectory   = isDirectory   ?? false
        self.isApplication = isApplication ?? false
    }
    
    static func == (lhs: DockFolderItem, rhs: DockFolderItem) -> Bool {
        return lhs.path == rhs.path
    }
}
