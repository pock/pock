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
import Zip

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
                let shouldSkipConfirm = index > 0
                let shouldForceReload = index < (widgets.count - 1)
                let needsReload       = shouldForceReload == false
                let name              = index == 0 ? "Default widgets" : nil
                let author            = index == 0 ? "Pock" : nil
                let label             = index == 0 ? "Tap to install default widgets".localized : nil
                self?.installWidget(
                    from:        url,
                    name:        name,
                    author:      author,
                    label:       label,
                    skipConfirm: shouldSkipConfirm,
                    forceReload: shouldForceReload,
                    needsReload: needsReload
                ) { _ in
                    sleep(2)
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }
    }
    
    // MARK: Download remote widgets
    internal func installWidget(from url:     URL?,
                                name:         String?,
                                author:       String?,
                                label:        String?,
                                skipConfirm:  Bool,
                                forceReload:  Bool,
                                needsReload:  Bool,
                                _ completion: ((Bool) -> Void)? = nil) {
        guard let url = url else {
            let error = NSError(domain: "WidgetDispatcher:installWidget", code: 404, userInfo: ["description": "Can't read widget remote url."])
            NSLog("[\(error.domain)]: \(error.code) - \(error.description)")
            completion?(false)
            return
        }
        background {
            let task = URLSession(configuration: .default).downloadTask(with: url) { [weak self] tmpPath, response, error in
                guard error == nil, let tmpPath = tmpPath else {
                    completion?(false)
                    return
                }
                guard let widgetName = response?.url?.lastPathComponent.replacingOccurrences(of: ".zip", with: "") else {
                    completion?(false)
                    return
                }
                let path = tmpPath.deletingLastPathComponent().appendingPathComponent("\(widgetName).zip")
                let dest = path.deletingLastPathComponent()
                do {
                    try FileManager.default.moveItem(at: tmpPath, to: path)
                    try Zip.unzipFile(path, destination: dest, overwrite: true, password: nil)
                    try FileManager.default.removeItem(at: path)
                    try self?.openProcessControllerForWidget(
                        at:          dest.appendingPathComponent(widgetName).relativePath,
                        process:     .install,
                        name:        name,
                        author:      author,
                        label:       label,
                        skipConfirm: skipConfirm,
                        forceReload: forceReload,
                        needsReload: needsReload
                    ) { success in
                        completion?(success)
                    }
                } catch {
                    completion?(false)
                }
            }
            task.resume()
        }
    }
    
    // MARK: Process
    internal func openProcessControllerForWidget(at path:     String?,
                                                 process:     ProcessWidgetController.Process,
                                                 name:        String? = nil,
                                                 author:      String? = nil,
                                                 label:       String? = nil,
                                                 skipConfirm: Bool    = false,
                                                 forceReload: Bool    = false,
                                                 needsReload: Bool    = true,
                                                 _ completion: ((Bool) -> Void)? = nil) throws {
        guard let path = path else {
            return
        }
        try openProcessControllerForWidget(
            at:          URL(string: path),
            process:     process,
            name:        name,
            author:      author,
            label:       label,
            skipConfirm: skipConfirm,
            forceReload: forceReload,
            needsReload: needsReload,
            completion
        )
    }
    internal func openProcessControllerForWidget(at url:      URL?,
                                                 process:     ProcessWidgetController.Process,
                                                 name:        String? = nil,
                                                 author:      String? = nil,
                                                 label:       String? = nil,
                                                 skipConfirm: Bool    = false,
                                                 forceReload: Bool    = false,
                                                 needsReload: Bool    = true,
                                                 _ completion: ((Bool) -> Void)? = nil) throws {
        guard let url = url else {
            return
        }
        async {
            /// load Pock main controller if needed
            if AppDelegate.default.navController == nil {
                AppDelegate.default.reloadPock()
            }
            /// load widget info
            let widgetInfo = try WidgetInfo(path: url)
            /// instantiate process widget controller
            let processWidgetController = ProcessWidgetController.processWidget(
                withInfo:    widgetInfo,
                process:     process,
                skipConfirm: skipConfirm,
                forceReload: forceReload,
                needsReload: needsReload,
                completion)
            processWidgetController?.pushOnMainNavigationController()
            if let name = name {
                processWidgetController?.nameLabel.stringValue = name
            }
            if let author = author {
                processWidgetController?.authorLabel.stringValue = author
            }
            if let label = label {
                processWidgetController?.infoLabel.stringValue = label
            }
        }
    }
    
}
