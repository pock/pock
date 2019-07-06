//
//  CCSleepItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class CCSleepItem: ControlCenterItem {
    
    override var title: String  { return "sleep" }
    
    override var icon:  NSImage { return NSImage(named: title)! }
    
    override func action() -> Any? {
        SystemHelper.sleep()
        return nil
    }
    
}
