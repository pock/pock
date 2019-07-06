//
//  ControlCenterItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class ControlCenterItem {
    
    var parentWidget: ControlCenterWidget?
    
    var enabled: Bool {
        get {
            return false
        }
    }
    
    init(parentWidget: ControlCenterWidget?) {
        self.parentWidget = parentWidget
    }
    
    var title: String {
        get {
            fatalError("Property `title` must be override in subclasses.")
        }
    }
    
    var icon: NSImage {
        get {
            fatalError("Property `icon` must be override in subclasses.")
        }
    }
    
    @discardableResult
    func action() -> Any? {
        fatalError("Function `action()` must be override in subclasses.")
    }
    
    func longPressAction() {
        /* Function `longPressAction()` can be override in subclasses. */
    }
    
    func didSlide(at value: Double) {
        /* Function `didSlide(at:Double)` can be override in subclasses. */
    }
}
