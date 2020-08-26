//
//  PockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation

class PKWidgetViewController: NSViewController {
    private weak var widgetItem: PKWidgetTouchBarItem?
    convenience init(widgetItem: PKWidgetTouchBarItem) {
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
        #if DEBUG
            print("[\(type(of: self))]: Widget deinit called.")
        #endif
    }
}

class PKWidgetTouchBarItem: NSCustomTouchBarItem {
    
    private var widget: PKWidget?
    
    override var customizationLabel: String! {
        get {
            return widget?.customizationLabel
        }
        set {
            widget?.customizationLabel = newValue
        }
    }
    
    convenience init(widget: PKWidget) {
        self.init(identifier: widget.identifier)
        self.widget = widget
        self.initialize(for: widget)
    }
    
    private func initialize(for widget: PKWidget) {
        let controller      = PKWidgetViewController(widgetItem: self)
        self.viewController = controller
        controller.view     = widget.view
    }
    
    deinit {
        #if DEBUG
            print("[PockWidget]: [\(widget?.identifier.rawValue ?? "Unknown widget")] - deinit called.")
        #endif
        viewController = nil
        widget         = nil
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
