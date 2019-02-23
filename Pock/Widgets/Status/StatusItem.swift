//
//  StatusItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class StatusItem {
    
    var title: String {
        get {
            fatalError("Property `title` must be override in subclasses.")
        }
    }
    
    var view: NSView {
        get {
            fatalError("Property `icon` must be override in subclasses.")
        }
    }
    
    func action() {
        fatalError("Function `action()` must be override in subclasses.")
    }
}
