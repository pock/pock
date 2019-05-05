//
//  PockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation

class PockWidgetViewController: NSViewController {
    weak var widget: PockWidget?
    override func viewWillAppear() {
        super.viewWillAppear()
        self.widget?.viewWillAppear()
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        self.widget?.viewDidAppear()
    }
    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.widget?.viewWillDisappear()
    }
    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.widget?.viewDidDisappear()
    }
    deinit {
        if !isProd { print("[\(type(of: self))]: Widget deinit called.") }
    }
}

class PockWidget: NSCustomTouchBarItem {
    
    override init(identifier: NSTouchBarItem.Identifier) {
        super.init(identifier: identifier)
        self.initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initialize()
    }
    
    private func initialize() {
        let controller      = PockWidgetViewController()
        controller.widget   = self
        self.viewController = controller
        customInit()
    }
    
    deinit {
        viewController = nil
        if !isProd { print("[PockWidget]: [\(type(of: self))] - deinit called.") }
    }
    
    func customInit() {
        fatalError("Function `customInit()` must be override in subclasses.")
    }
    
    func viewWillAppear() {
        /// fatalError("Function `viewWillAppear()` must be override in subclasses.")
    }
    
    func viewDidAppear() {
        /// fatalError("Function `viewDidAppear()` must be override in subclasses.")
    }
    
    func viewWillDisappear() {
        /// fatalError("Function `viewWillDisappear()` must be override in subclasses.")
    }
    
    func viewDidDisappear() {
        /// fatalError("Function `viewDidDisappear()` must be override in subclasses.")
    }
    
    func set(view: NSView) {
        self.viewController?.view = view
    }
    
}
