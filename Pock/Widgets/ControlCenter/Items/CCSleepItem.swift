//
//  CCSleepItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class CCSleepItem: ControlCenterItem {
    
    override var enabled: Bool{ return Defaults[.shouldShowSleepItem] }
    
    override var title: String  { return "sleep" }
    
    override var icon:  NSImage { return NSImage(named: title)!.resize(w: 30, h: 30) }
    
    override func action() -> Any? {
        SystemHelper.lock()
        SystemHelper.sleep()
        return nil
    }
    
}
