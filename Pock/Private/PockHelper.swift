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
    static let didAskToInstallDefaultWidgets = Defaults.Key<Bool>("didAskToInstallDefaultWidgets", default: false)
}

internal class PockHelper {
    
    /// Singleton
    public static let `default`: PockHelper = PockHelper()
	
	/// Core
	private var session: URLSession?
    
	/// Endpoint
	#if DEBUG
	private let defaultsURLString: String = "https://pock.dev/api/dev/defaults.php"
	#else
	private let defaultsURLString: String = "https://pock.dev/api/defaults.php"
	#endif
	
    internal func relaunchPock() {
        guard let relaunch_path = Bundle.main.path(forResource: "Relaunch", ofType: nil) else {
            return
        }
        let task = Process()
        task.launchPath = relaunch_path
        task.arguments  = ["\(ProcessInfo.processInfo.processIdentifier)"]
        task.launch()
    }
    
	// MARK: Default widgets (fetch)
	private func _fetchDefaultWidgets(_ completion: @escaping ([String]) -> Void) {
		guard let defaultsURL = URL(string: "\(defaultsURLString)?core=\(PockUpdater.appVersion)") else {
			completion([])
			return
		}
		async { [weak self] in
			let request = URLRequest(url: defaultsURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
			self?.session?.finishTasksAndInvalidate()
			self?.session = URLSession(configuration: .ephemeral)
			self?.session?.dataTask(with: request, completionHandler: { [weak self] data, response, error in
				defer {
					self?.session?.finishTasksAndInvalidate()
					self?.session = nil
				}
				guard let data = data, let response = try? JSONDecoder().decode([String: String].self, from: data) else {
					completion([])
					return
				}
				background { [completion] in
					completion(Array(response.values))
				}
			}).resume()
		}
	}
	
    // MARK: Default widgets (install)
	internal func installDefaultWidgets(_ completion: (() -> Void)?) {
		/// Get default widgets list from remote based on current core version
		_fetchDefaultWidgets() { [weak self] widgets in
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
								Defaults[.didAskToInstallDefaultWidgets] = true
								completion?()
							}
						},
						/// completion
						{ _ in
							if index == 0 {
								Defaults[.didAskToInstallDefaultWidgets] = true
							}
							sleep(2)
							semaphore.signal()
						}
					)
				} catch {
					let error = NSError(domain: "WidgetDispatcher:installDefaultWidgets", code: 404, userInfo: ["description": error.localizedDescription])
					NSLog("[Pock][\(error.domain)]: \(error.code) - \(error.description)")
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
