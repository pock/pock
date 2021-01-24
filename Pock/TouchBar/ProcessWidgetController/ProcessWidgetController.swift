//
//  ProcessWidgetController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 03/09/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import Foundation
import PockKit
import Zip

private let widgetIcon: NSImage? = NSImage(named: "WidgetsManagerList")

public class ProcessWidgetController: PKTouchBarMouseController {
    
    // MARK: UI State
    internal enum UIState {
        case unknown, download, install, remove, processing, downloading, completed(success: Bool), reloading, empty
    }
    
    // MARK: Widget Process
    public enum Process {
        case unknown, download, install, update, remove, empty
    }
    
    // MARK: Configutation
    public struct Configuration {
        var process:       		Process
        var remoteURL:     		URL?
        var widgetInfo:    		WidgetInfo?
        var skipInstallConfirm: Bool
        var forceDownload: 		Bool
        var forceReload:   		Bool
        var needsReload:   		Bool
        var name:          		String?
        var author:        		String?
        var label:         		String?
		public static func `default`(remoteURL: URL?, process: Process = .download) -> Configuration {
            return Configuration(process: process, remoteURL: remoteURL, widgetInfo: nil, skipInstallConfirm: true, forceDownload: false, forceReload: false, needsReload: true)
        }
        public static func `default`(process: Process, widgetInfo: WidgetInfo?) -> Configuration {
            return Configuration(process: process, remoteURL: nil, widgetInfo: widgetInfo, skipInstallConfirm: true, forceDownload: false, forceReload: false, needsReload: true)
        }
    }
    
    /// UI Elements
    @IBOutlet public private(set) weak var nameLabel:    NSTextField!
    @IBOutlet public private(set) weak var authorLabel:  NSTextField!
    @IBOutlet public private(set) weak var infoLabel:    NSTextField!
    @IBOutlet private weak var iconView:     NSImageView!
    @IBOutlet private weak var cancelButton: NSButton!
    @IBOutlet private weak var actionButton: NSButton!
    
    /// Core
    private var configuration: Configuration!
    private var completion:  ((Bool) -> Void)? = nil
    private var willDismiss: (() -> Void)?     = nil
    
    private var widgetName: String {
        return configuration.widgetInfo?.name ?? configuration.remoteURL?.lastPathComponent.replacingOccurrences(of: ".zip", with: "") ?? "Unknown"
    }
    
    private var state: UIState = .unknown {
        didSet {
            updateUIState(to: state)
        }
    }
    private var process: Process {
        get {
            return configuration.process
        }
        set {
            configuration.process = newValue
            switch newValue {
			case .install:
                state = .install
            case .remove:
                state = .remove
            case .download, .update:
                state = .download
            default:
                state = .unknown
            }
        }
    }
	
	// MARK: Mouse Support
	private var buttonWithMouseOver:   NSButton?
	private var touchBarView: NSView {
		if let view = actionButton.superview(subclassOf: "NSTouchBarView") {
			return view
		}
		fatalError("Can't find NSTouchBarView object.")
	}
	public override var visibleRectWidth: CGFloat {
		get { return touchBarView.visibleRect.width } set { /**/ }
	}
	public override var parentView: NSView! {
		get { return touchBarView } set { /**/ }
	}
    
    // MARK: Initialiser
    public class func processWidget(configuration: Configuration, _ willDismiss: (() -> Void)? = nil, _ completion: ((Bool) -> Void)? = nil) -> ProcessWidgetController? {
		if configuration.remoteURL != nil || configuration.widgetInfo != nil || configuration.process == .empty {
			let returnable: ProcessWidgetController = ProcessWidgetController.load()
			returnable.configuration = configuration
			returnable.process       = configuration.process
			returnable.willDismiss   = willDismiss
			returnable.completion    = completion
			if configuration.process == .empty {
				returnable.updateUIState(to: .empty)
			}
			return returnable
        }
		return nil
    }
    
    // MARK: Overrides
    public override func present() {
        super.present()
        updateLeftDetailView()
    }
    
    deinit {
		#if DEBUG
		NSLog("[ProcessWidgetController][\(process)][\(state)]: Deinit ProcessWidgetController for widget: `\(widgetName)`")
		#endif
    }
    
    // MARK: UI Methods
    private func updateLeftDetailView() {
        nameLabel.stringValue   = configuration.name   ?? widgetName
        authorLabel.stringValue = configuration.author ?? configuration.widgetInfo?.author ?? "Unknown"
        nameLabel.sizeToFit()
        authorLabel.sizeToFit()
    }
    
    private func updateUIState(to state: UIState) {
        updateLeftDetailView()
        switch state {
		case .empty:
			cancelButton.isHidden   = true
			infoLabel.stringValue	= "Add widgets to Pock".localized
			actionButton.title		= "Customize".localized
			actionButton.tag		= -2
			actionButton.bezelColor = NSColor.systemBlue
			actionButton.isEnabled  = true
			iconView.isHidden		= false
			async(after: 0.5) { [weak self] in
				self?.addIconViewAnimation()
			}
			
		case .reloading:
			cancelButton.isHidden   = true
			infoLabel.stringValue	= "Reloading...".localized
			actionButton.title		= "Reload".localized
			actionButton.tag		= 3
			actionButton.bezelColor = NSColor.systemGray
			actionButton.isEnabled  = false
			iconView.isHidden		= true
        
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
            if configuration.skipInstallConfirm {
                installLocalWidget()
                return
            }
            cancelButton.isHidden   = false
            infoLabel.stringValue   = configuration.label ?? "Tap to install".localized + " `\(widgetName)`"
            actionButton.title      = "Install".localized
            actionButton.tag        = 0
            actionButton.bezelColor = NSColor.systemBlue
            actionButton.isEnabled  = true
            iconView.isHidden       = false
            async(after: 0.5) { [weak self] in
                self?.addIconViewAnimation()
            }
        
		case .remove:
            cancelButton.isHidden   = false
            infoLabel.stringValue   = configuration.label ?? "Are you sure you want to remove".localized + " `\(widgetName)`?"
            actionButton.title      = "Remove".localized
            actionButton.tag        = 1
            actionButton.bezelColor = NSColor.systemRed
            actionButton.isEnabled  = true
            iconView.isHidden       = false
            async(after: 0.5) { [weak self] in
                self?.addIconViewAnimation()
            }
        
		case .download:
            if configuration.forceDownload {
                downloadRemoteWidget()
                return
            }
            cancelButton.isHidden   = false
            infoLabel.stringValue   = configuration.label ?? ((process == .update ? "Update" : "Download").localized + " `\(widgetName)`")
            actionButton.title      = (process == .update ? "Update" : "Download").localized
            actionButton.tag        = 2
            actionButton.bezelColor = NSColor.systemBlue
            actionButton.isEnabled  = true
            iconView.isHidden       = false
            async(after: 0.5) { [weak self] in
                self?.addIconViewAnimation()
            }
        
		case .processing:
            cancelButton.isHidden   = true
            infoLabel.stringValue   = "Processing".localized + " `\(widgetName)`"
            actionButton.tag        = -1
            actionButton.title      = "Install".localized
            actionButton.bezelColor = NSColor.systemGray.withAlphaComponent(0.3725)
            actionButton.isEnabled  = false
            iconView.isHidden       = true
            removeIconViewAnimation()
        
		case .downloading:
			cancelButton.isHidden   = configuration.forceDownload
            infoLabel.stringValue   = "Downloading".localized + " `\(widgetName)`"
            actionButton.tag        = -1
			actionButton.title      = (process == .update ? "Update" : "Download").localized
            actionButton.bezelColor = NSColor.systemGray.withAlphaComponent(0.3725)
            actionButton.isEnabled  = false
            iconView.isHidden       = true
            removeIconViewAnimation()
        
		case .completed(let success):
            completion?(success)
            if configuration.needsReload == false {
                return
            }
            if configuration.forceReload {
                PockHelper.default.relaunchPock()
                return
            }
            let processName: String = {
                switch process {
                case .unknown:  return "WTF?".localized
                case .install:  return "Installed".localized
				case .update:   return "Updated".localized
                case .remove:   return "Removed".localized
                case .download: return "Downloaded".localized
				case.empty:		return ""
                }
            }()
            cancelButton.isHidden   = true
            infoLabel.stringValue   = success ? "\(processName)!".localized : "`\(widgetName)`" + "can't be \(processName).".localized
            infoLabel.stringValue  += " Tap to reload Pock".localized
            actionButton.title      = "Reload".localized
            actionButton.tag        = 3
            actionButton.bezelColor = NSColor.systemGray.withAlphaComponent(0.6725)
            actionButton.isEnabled  = true
            iconView.isHidden       = false
            addIconViewAnimation()
        }
    }
	
	// MARK: Mouse stuff
	public override func screenEdgeController(_ controller: PKScreenEdgeController, mouseClickAtLocation location: NSPoint, in view: NSView) {
		/// Check for button
		guard let button = button(at: location) else {
			return
		}
		actionButtonPressed(button)
	}
	
	public override func updateCursorLocation(_ location: NSPoint?) {
		super.updateCursorLocation(location)
		buttonWithMouseOver?.isHighlighted = false
		buttonWithMouseOver = nil
		buttonWithMouseOver = button(at: location)
		buttonWithMouseOver?.isHighlighted = true
	}
	
	private func button(at location: NSPoint?) -> NSButton? {
		guard let view = parentView.subview(in: parentView, at: location, of: "NSTouchBarItemContainerView") else {
			return nil
		}
		return view.findViews(subclassOf: NSButton.self).first
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
        case 2: // download
            downloadRemoteWidget()
        case 3: // reload
			state = .reloading
			async(after: 0.75) {
				PockHelper.default.relaunchPock()
			}
        default: // close
            willDismiss?()
            dismiss()
        }
    }
    private func downloadRemoteWidget() {
        guard let url = configuration.remoteURL else {
            state = .completed(success: false)
            return
        }
        state = .downloading
		background { [weak self] in
			do {
				try WidgetsDispatcher.default.downloadWidget(atURL: url) { [weak self] newState, widgetInfo in
					guard let info = widgetInfo else {
						self?.state = .completed(success: false)
						return
					}
					self?.configuration.remoteURL  = nil
					self?.configuration.widgetInfo = info
					async(after: 0.025) { [weak self, newState] in
						self?.state = newState
					}
				}
			} catch {
				async { [weak self] in
					self?.state = .completed(success: false)
				}
				NSLog("[ProcessWidgetController]: Can't download widget. Reason: \(error.localizedDescription)")
			}
		}
	}

    private func installLocalWidget() {
        state = .processing
        background { [weak self] in
            do {
                try WidgetsDispatcher.default.installWidget(at: self?.configuration.widgetInfo?.path)
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
                try WidgetsDispatcher.default.removeWidget(atPath: self?.configuration.widgetInfo?.path?.path)
                async { [weak self] in
                    self?.state = .completed(success: true)
                }
            } catch {
                async { [weak self] in
                    self?.state = .completed(success: false)
                }
                NSLog("[ProcessWidgetController]: Can't uninstall widget. Reason: \(error.localizedDescription)")
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
