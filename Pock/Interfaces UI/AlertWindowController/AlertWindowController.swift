//
//  AlertWindowController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import AppKit

public struct AlertAction {
    let title: String?
    let action: (() -> Void)?
    public static let `default` = AlertAction(title: "Close".localized, action: nil)
}

public class AlertWindowController: NSWindowController {

    /// Core
    public override var windowNibName: NSNib.Name? {
        return NSNib.Name("AlertWindowController")
    }
    
    /// UI Elements
    @IBOutlet private weak var messageView:  NSTextField!
    @IBOutlet private weak var actionButton: NSButton!
    
    /// Data
    private var alertTitle:   String?
    private var alertMessage: String?
    private var alertAction:  AlertAction?
    
    init(title: String, message: String?, action: AlertAction? = .default) {
        self.alertTitle   = title
        self.alertMessage = message
        self.alertAction  = action
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadWindow()
    }
    
    public override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.title           = self.alertTitle         ?? "Unknown"
        self.actionButton.title      = self.alertAction?.title ?? "Close"
        self.messageView.stringValue = self.alertMessage       ?? "Unknown"
        self.actionButton.isHidden   = alertAction == nil
    }
    
    @IBAction func actionButtonHandler(_ sender: Any) {
        self.close()
        self.alertAction?.action?()
    }
}
