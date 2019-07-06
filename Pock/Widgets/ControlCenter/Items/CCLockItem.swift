//
//  CCLockItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCLockItem: ControlCenterItem {
    
    override var title: String  { return "lock" }
    
    override var icon:  NSImage { return NSImage(named: NSImage.lockLockedTemplateName)! }
    
    override func action() -> Any? {
        SystemHelper.lock()
        return nil
    }
    
}
