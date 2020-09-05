//
//  WidgetsManagerInstallPane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/09/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import AppKit
import Preferences

class WidgetsManagerInstallPane: NSViewController, PreferencePane {

    // MARK: State
    private enum State {
        case install, processing, completed(success: Bool)
    }
    
    // MARK: Preferenceable
    var preferencePaneIdentifier: Preferences.PaneIdentifier = Preferences.PaneIdentifier.widgets_manager_install
    let preferencePaneTitle:      String     = "Install".localized
    var toolbarItemIcon:          NSImage    = NSImage(named: "WidgetsManagerInstall")!
    
    // MARK: UI Elements
    /// Drag&Drop
    @IBOutlet private weak var dragAndDropContainerView: RoundedRectView!
    @IBOutlet private weak var dragAndDropTopLayer:      DestinationView!
    @IBOutlet private weak var dragAndDropInfoLabel:     NSTextField!
    /// Remote install
    @IBOutlet private weak var remoteInstallContainerView: NSView!
    @IBOutlet private weak var remoteInstallTextField:     NSTextField!
    @IBOutlet private weak var remoteInstallButton:        NSButton!
    
    /// Core
    private var remoteUrlString: String {
        return remoteInstallTextField.stringValue
    }
    private var canDownloadFromRemote: Bool {
        return remoteUrlString.isEmpty == false // TODO: Replace with URL regex
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// Remote
        remoteInstallTextField.delegate = self
        updateState(to: .install)
        /// Drag&Drop
        dragAndDropTopLayer.completion = { path in
            if let widgetInfo = try? WidgetInfo(path: path) {
                let configuration = ProcessWidgetController.Configuration.default(process: .install, widgetInfo: widgetInfo)
                try? PockHelper.default.openProcessControllerForWidget(configuration: configuration)
            }
        }
    }
    
    private func updateState(to state: State) {
        switch state {
        case .install:
            remoteInstallTextField.textColor = .white
            remoteInstallTextField.isEnabled = true
            remoteInstallButton.isEnabled    = canDownloadFromRemote
        case .processing:
            remoteInstallTextField.textColor = NSColor.systemGray.withAlphaComponent(0.6)
            remoteInstallTextField.isEnabled = false
            remoteInstallButton.isEnabled    = false
        case .completed(let success):
            remoteInstallTextField.textColor = success ? .white : .systemRed
            remoteInstallTextField.isEnabled = true
            remoteInstallButton.isEnabled    = canDownloadFromRemote
        }
    }
    
}

// MARK: Actions
extension WidgetsManagerInstallPane {
    @IBAction private func didClickOnDownloadButton(_ button: NSButton?) {
        guard let url = URL(string: remoteInstallTextField.stringValue) else {
            updateState(to: .completed(success: false))
            return
        }
        do {
            updateState(to: .processing)
            let configuration = ProcessWidgetController.Configuration.default(remoteURL: url)
            try PockHelper.default.openProcessControllerForWidget(
                configuration: configuration,
                /// Will dismiss
                { [weak self] in
                    self?.updateState(to: .install)
                },
                /// Completion
                { [weak self] success in
                    self?.updateState(to: .completed(success: success))
                }
            )
        } catch {
            remoteInstallTextField.textColor = .systemRed
            NSLog("[WidgetsManagerInstallPane]: Can't install remote widget: \(error.localizedDescription)")
        }
    }
}

// MARK: NSTextFieldDelegate
extension WidgetsManagerInstallPane: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        remoteInstallTextField.textColor = .white
        remoteInstallButton.isEnabled    = remoteInstallTextField.stringValue.isEmpty == false
    }
}
