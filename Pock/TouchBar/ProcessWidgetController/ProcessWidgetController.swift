//
//  ProcessWidgetController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 03/09/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import Foundation
import PockKit

private let widgetIcon: NSImage? = NSImage(named: "WidgetsManagerList")

public class ProcessWidgetController: PKTouchBarController {
    
    // MARK: UI State
    private enum UIState {
        case unknown, install, remove, processing, completed(success: Bool)
    }
    
    // MARK: Widget Process
    public enum Process {
        case unknown, install, remove
    }
    
    /// UI Elements
    @IBOutlet public private(set) weak var nameLabel:    NSTextField!
    @IBOutlet public private(set) weak var authorLabel:  NSTextField!
    @IBOutlet public private(set) weak var infoLabel:    NSTextField!
    @IBOutlet private weak var iconView:     NSImageView!
    @IBOutlet private weak var cancelButton: NSButton!
    @IBOutlet private weak var actionButton: NSButton!
    
    /// Core
    private var widgetInfo:  WidgetInfo!
    private var skipConfirm: Bool = false
    private var forceReload: Bool = false
    private var needsReload: Bool = true
    private var completion: ((Bool) -> Void)? = nil
    
    private var state: UIState = .unknown {
        didSet {
            updateUIState(to: state)
        }
    }
    private var process: Process = .unknown {
        didSet {
            switch process {
            case .install:
                state = .install
            case .remove:
                state = .remove
            default:
                state = .unknown
            }
        }
    }
    
    // MARK: Initialiser
    public class func processWidget(withInfo widgetInfo:  WidgetInfo?,
                                             process:     Process,
                                             skipConfirm: Bool = false,
                                             forceReload: Bool = false,
                                             needsReload: Bool = true,
                                             _ completion: ((Bool) -> Void)? = nil) -> ProcessWidgetController? {
        guard let widgetInfo = widgetInfo else {
            return nil
        }
        let returnable: ProcessWidgetController = ProcessWidgetController.load()
        returnable.completion  = completion
        returnable.skipConfirm = skipConfirm
        returnable.forceReload = forceReload
        returnable.needsReload = needsReload
        returnable.widgetInfo  = widgetInfo
        returnable.process     = process
        return returnable
    }
    
    // MARK: Overrides
    public override func present() {
        super.present()
        nameLabel.stringValue   = widgetInfo.name
        authorLabel.stringValue = widgetInfo.author
        nameLabel.sizeToFit()
        authorLabel.sizeToFit()
    }
    
    deinit {
        print("Deinit ProcessWidgetController for widget: `\(widgetInfo.name)`")
    }
    
    // MARK: UI Methods
    private func updateUIState(to state: UIState) {
        switch state {
        case .unknown:
            cancelButton.isHidden   = false
            infoLabel.stringValue   = "Something went wrong".localized
            actionButton.title      = "Close".localized
            actionButton.tag        = -1
            actionButton.bezelColor = NSColor.systemGray
            actionButton.isEnabled  = true
            iconView.isHidden       = false
            async(after: 0.5) { [weak self] in
                self?.addIconViewAnimation()
            }
        case .install:
            if skipConfirm {
                installLocalWidget()
                return
            }
            cancelButton.isHidden   = false
            infoLabel.stringValue   = "Tap to install `\(widgetInfo.name)`".localized
            actionButton.title      = "Install".localized
            actionButton.tag        = 0
            actionButton.bezelColor = NSColor.systemGreen
            actionButton.isEnabled  = true
            iconView.isHidden       = false
            async(after: 0.5) { [weak self] in
                self?.addIconViewAnimation()
            }
        case .remove:
            if skipConfirm {
                removeLocalWidget()
                return
            }
            cancelButton.isHidden   = false
            infoLabel.stringValue   = "Are you sure you want to remove".localized + " `\(widgetInfo.name)`?"
            actionButton.title      = "Remove".localized
            actionButton.tag        = 1
            actionButton.bezelColor = NSColor.systemRed
            actionButton.isEnabled  = true
            iconView.isHidden       = false
            async(after: 0.5) { [weak self] in
                self?.addIconViewAnimation()
            }
        case .processing:
            cancelButton.isHidden   = true
            infoLabel.stringValue   = "Processing".localized + " `\(widgetInfo.name)`"
            actionButton.tag        = -1
            actionButton.title      = "Install".localized
            actionButton.bezelColor = NSColor.systemGray
            actionButton.isEnabled  = false
            iconView.isHidden       = true
            removeIconViewAnimation()
        case .completed(let success):
            completion?(success)
            if needsReload == false {
                return
            }
            if forceReload {
                PockHelper.default.relaunchPock()
                return
            }
            let processName: String = {
                switch process {
                case .unknown: return "WTF?".localized
                case .install: return "installed".localized
                case .remove:  return "removed".localized
                }
            }()
            cancelButton.isHidden   = true
            infoLabel.stringValue   = success ? "Done!".localized : "`\(widgetInfo.name)`" + "can't be \(processName).".localized
            infoLabel.stringValue  += " Tap to reload Pock".localized
            actionButton.title      = "Reload".localized
            actionButton.tag        = 2
            actionButton.bezelColor = NSColor.systemGray
            actionButton.isEnabled  = true
            iconView.isHidden       = false
            addIconViewAnimation()
        }
    }
    
}

// MARK: Actions
extension ProcessWidgetController {
    @IBAction private func actionButtonPressed(_ sender: NSButton?) {
        switch sender?.tag {
        case 0: // install
            installLocalWidget()
        case 1: // remove
            removeLocalWidget()
        case 2: // reload
            PockHelper.default.relaunchPock()
        default: // close
            dismiss()
        }
    }
    private func installLocalWidget() {
        state = .processing
        background { [weak self] in
            do {
                try WidgetsDispatcher.default.installWidget(at: self?.widgetInfo?.path)
                NotificationCenter.default.post(name: .didInstallWidget, object: nil)
                async { [weak self] in
                    self?.state = .completed(success: true)
                }
            } catch {
                async { [weak self] in
                    self?.state = .completed(success: false)
                }
                NSLog("[ProcessWidgetController]: Can't install widget. Reason: \(error.localizedDescription)")
            }
        }
    }
    private func removeLocalWidget() {
        state = .processing
        background { [weak self] in
            do {
                try WidgetsDispatcher.default.removeWidget(atPath: self?.widgetInfo?.path?.path)
                async { [weak self] in
                    self?.state = .completed(success: true)
                }
            } catch {
                async { [weak self] in
                    self?.state = .completed(success: false)
                }
                print("[ProcessWidgetController]: Can't uninstall widget. Reason: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: Icon bounce animation
extension ProcessWidgetController {
    private func addIconViewAnimation() {
        iconView.superview?.layout()
        let slideAnimation = CABasicAnimation(keyPath: "position.x")
        slideAnimation.duration  = 0.475
        slideAnimation.fromValue = (iconView.superview?.frame.origin.x ?? 0) + 3.3525
        slideAnimation.toValue   = (iconView.superview?.frame.origin.x ?? 0) - 1.3525
        slideAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        slideAnimation.autoreverses = true
        slideAnimation.repeatCount = .greatestFiniteMagnitude
        iconView.superview?.layer?.add(slideAnimation, forKey: "bounce_animation")
    }
    private func removeIconViewAnimation() {
        iconView.superview?.layer?.removeAnimation(forKey: "bounce_animation")
    }
}
