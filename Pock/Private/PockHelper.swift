//
//  PockHelper.swift
//  Pock
//
//  Created by Pierluigi Galdi on 02/09/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import Foundation
import PockKit
import Defaults

extension Defaults.Keys {
    static let didAskToInstallDefaultsWidgets = Defaults.Key<Bool>("didAskToInstallDefaultsWidgets", default: false)
}

internal class PockHelper {
    
    /// Singleton
    public static let `default`: PockHelper = PockHelper()
    
    static var didAskToInstallDefaultWidgets: Bool {
        get {
            return Defaults[.didAskToInstallDefaultsWidgets]
        }
        set {
            Defaults[.didAskToInstallDefaultsWidgets] = newValue
        }
    }
	
	static var allowBlankTouchBar: Bool {
		get {
			return Defaults[.allowBlankTouchBar]
		}
		set {
			Defaults[.allowBlankTouchBar] = newValue
		}
	}
    
    internal func relaunchPock() {
        guard let relaunch_path = Bundle.main.path(forResource: "Relaunch", ofType: nil) else {
            return
        }
        let task = Process()
        task.launchPath = relaunch_path
        task.arguments  = ["\(ProcessInfo.processInfo.processIdentifier)"]
        task.launch()
    }
    
    internal func reloadTouchBarServer(_ completion: ((Bool) -> Void)? = nil) {
        TouchBarHelper.reloadTouchBarServer { success in
            completion?(success)
        }
    }
    
    // MARK: Default widgets
    internal func installDefaultWidgets() {
        let widgets = [
            "https://pock.dev/widgets/defaults/ControlCenter.pock.zip",
            "https://pock.dev/widgets/defaults/Dock.pock.zip",
            "https://pock.dev/widgets/defaults/Esc.pock.zip",
            "https://pock.dev/widgets/defaults/NowPlaying.pock.zip",
            "https://pock.dev/widgets/defaults/Status.pock.zip",
            "https://pock.dev/widgets/defaults/Weather.pock.zip"
        ]
        background { [weak self] in
            let semaphore = DispatchSemaphore(value: 0)
            for (index, widgetUrl) in widgets.enumerated() {
                guard let url = URL(string: widgetUrl) else {
                    continue
                }
                let shouldForceDownload = index > 0
                let shouldForceReload   = index < (widgets.count - 1)
                let needsReload         = shouldForceReload == false
                let name                = index == 0 ? "Default widgets" : nil
                let author              = index == 0 ? "Pock" : nil
                let label               = index == 0 ? "Tap to install default widgets".localized : nil
                do {
                    let configuration = ProcessWidgetController.Configuration(
                        process:       .download,
                        remoteURL:     url,
                        widgetInfo:    nil,
                        skipConfirm:   true,
                        forceDownload: shouldForceDownload,
                        forceReload:   shouldForceReload,
                        needsReload:   needsReload,
                        name:          name,
                        author:        author,
                        label:         label
                    )
                    try self?.openProcessControllerForWidget(
                        configuration: configuration,
                        /// willDismiss
                        {
                            if index == 0 {
                                PockHelper.didAskToInstallDefaultWidgets = true
                            }
                        },
                        /// completion
                        { _ in
                            if index == 0 {
                                PockHelper.didAskToInstallDefaultWidgets = true
                            }
                            sleep(2)
                            semaphore.signal()
                        }
                    )
                } catch {
                    let error = NSError(domain: "WidgetDispatcher:installDefaultWidgets", code: 404, userInfo: ["description": error.localizedDescription])
                    NSLog("[\(error.domain)]: \(error.code) - \(error.description)")
                    sleep(2)
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }
    }
    
    // MARK: Process
    internal func openProcessControllerForWidget(configuration: ProcessWidgetController.Configuration,
                                                 _ willDismiss: (() -> Void)?     = nil,
                                                 _ completion:  ((Bool) -> Void)? = nil) throws {
        guard let _: Any = configuration.remoteURL ?? configuration.widgetInfo else {
            return
        }
        async {
            /// load Pock main controller if needed
            if AppDelegate.default.navController == nil {
                AppDelegate.default.reloadPock()
            }
            /// instantiate process widget controller
            let processWidgetController = ProcessWidgetController.processWidget(configuration: configuration, willDismiss, completion)
            processWidgetController?.pushOnMainNavigationController()
        }
    }
	
	// MARK: No widget enabled
	internal func openProcessControllerForEmptyWidgets() {
		async {
			/// load Pock main controller if needed
			if AppDelegate.default.navController == nil {
				AppDelegate.default.reloadPock()
			}
			/// instantiate process widget controller
			let configuration = ProcessWidgetController.Configuration(process: .empty,
																	  remoteURL: nil,
																	  widgetInfo: nil,
																	  skipConfirm: false,
																	  forceDownload: false,
																	  forceReload: false,
																	  needsReload: false,
																	  name: "Welcome to Pock",
																	  author: "Widgets manager for MacBook's Touch Bar",
																	  label: nil)
			let processWidgetController = ProcessWidgetController.processWidget(configuration: configuration, {
				if let mainController = AppDelegate.default.navController?.rootController as? PockMainController {
					mainController.openCustomization()
				}
			}, { _ in })
			processWidgetController?.pushOnMainNavigationController()
		}
	}
    
}
