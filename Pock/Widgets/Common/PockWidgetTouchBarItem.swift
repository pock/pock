//
//  PockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation

class PockWidgetViewController: NSViewController {
    private weak var widgetItem: PockWidgetTouchBarItem?
    convenience init(widgetItem: PockWidgetTouchBarItem) {
        self.init()
        self.widgetItem = widgetItem
    }
    override func viewWillAppear() {
        super.viewWillAppear()
        self.widgetItem?.viewWillAppear()
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        self.widgetItem?.viewDidAppear()
    }
    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.widgetItem?.viewWillDisappear()
    }
    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.widgetItem?.viewDidDisappear()
    }
    deinit {
        if !isProd { print("[\(type(of: self))]: Widget deinit called.") }
    }
}

class PockWidgetTouchBarItem: NSCustomTouchBarItem {
    
    private var widget: PockWidget?
    
    override var customizationLabel: String! {
        get {
            return widget?.customizationLabel
        }
        set {
            widget?.customizationLabel = newValue
        }
    }
    
    convenience init(widget: PockWidget) {
        self.init(identifier: widget.identifier)
        self.widget = widget
        self.initialize(for: widget)
    }
    
    private func initialize(for widget: PockWidget) {
        let controller      = PockWidgetViewController(widgetItem: self)
        self.viewController = controller
        controller.view     = widget.view
    }
    
    deinit {
        viewController = nil
        if !isProd { print("[PockWidget]: [\(type(of: self))] - deinit called.") }
    }
    
    func viewWillAppear() {
        widget?.viewWillAppear?()
    }
    func viewDidAppear() {
        widget?.viewDidAppear?()
    }
    func viewWillDisappear() {
        widget?.viewWillDisappear?()
    }
    func viewDidDisappear() {
        widget?.viewDidDisappear?()
    }
    
}
