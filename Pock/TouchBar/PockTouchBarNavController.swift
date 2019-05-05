//
//  PockTouchBarNavController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class PockTouchBarNavController {
    
    weak var rootController:   PockTouchBarController?
    var childControllers: [PockTouchBarController] = []
    
    init(rootController: PockTouchBarController) {
        self.rootController = rootController
        self.push(rootController)
    }
    
}

extension PockTouchBarNavController {
    
    func push(_ controller: PockTouchBarController) {
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
    
}
