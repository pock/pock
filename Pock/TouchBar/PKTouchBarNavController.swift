//
//  PockTouchBarNavController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class PKTouchBarNavController {
    
    weak var rootController:   PKTouchBarController?
    var childControllers: [PKTouchBarController] = []
    
    var visibleController: PKTouchBarController? {
        return childControllers.last
    }
    
    init(rootController: PKTouchBarController) {
        self.rootController = rootController
        self.push(rootController)
    }
    
}

extension PKTouchBarNavController {
    
    func push(_ controller: PKTouchBarController) {
        childControllers.append(controller)
        controller.navController = self
        controller.present()
    }
    
    func popLastController() {
        var controller = childControllers.popLast()
        controller?.dismiss()
        controller = nil
    }
    
    func popToRootController() {
        for _ in 1..<childControllers.count {
            popLastController()
        }
    }
    
    func dismiss() {
        popToRootController()
        popLastController()
        childControllers.removeAll()
        rootController = nil
    }
    
    func minimize() {
        childControllers.forEach({ $0.minimize() })
    }
    
    func deminimize() {
        childControllers.forEach({ $0.present() })
    }
    
    func toggle() {
        if rootController?.isVisible ?? false {
            minimize()
        }else {
            deminimize()
        }
    }
    
}
