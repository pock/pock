//
//  WidgetsDispatcherr.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/11/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import PockKit
import Zip

public final class WidgetsDispatcher {
    
    /// Configuration
    public struct Configuration {
        let shouldDeleteAfterInstall: Bool
        static let `default`: Configuration = Configuration(shouldDeleteAfterInstall: false)
    }
    
    /// Singleton
    public static let `default`: WidgetsDispatcher = WidgetsDispatcher(configuration: .default)
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Core
    private var configuration: Configuration
    
    /// Data
    public private(set) var loadedWidgets: [PKWidget] = []
    
    /// Getters
    private var applicationSupportPockFolder: String {
        return FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Pock"
    }
    private var widgetsPath: String {
        return applicationSupportPockFolder + "/Widgets"
    }
    
    public func clearLoadedWidgets() {
        loadedWidgets.removeAll()
    }
    
    private func fileExists(at path: String?, isDirectory: Bool) -> Bool {
        guard let path = path else {
            return false
        }
        if !isDirectory {
            return FileManager.default.fileExists(atPath: path)
        }
        var directoryExists: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
        return directoryExists.boolValue
    }
    
    private func getWidgetPath(for name: String?) -> String? {
        guard let name = name else {
            return nil
        }
        return widgetsPath + "/\(name)" + (name.contains(".pock") ? "" : ".pock")
    }
    
    private var installedWidgetsPaths: [URL] {
        if !fileExists(at: applicationSupportPockFolder, isDirectory: true) {
            try? FileManager.default.createDirectory(atPath: applicationSupportPockFolder, withIntermediateDirectories: false, attributes: nil)
            try? FileManager.default.createDirectory(atPath: widgetsPath, withIntermediateDirectories: false, attributes: nil)
        }
        guard fileExists(at: widgetsPath, isDirectory: true) else {
            return []
        }
        let enumerator = FileManager.default.enumerator(atPath: widgetsPath)
        let widgetBundles = (enumerator?.allObjects as? [String] ?? []).filter{ $0.contains(".pock") && !$0.contains("disabled") && !$0.contains("/") }
        return widgetBundles.map({ widgetBundle in
            return URL(fileURLWithPath: "\(widgetsPath)/\(widgetBundle)")
        })
    }
    
    /// Get iinstalled widgets
    internal var installedWidgets: [WidgetInfo] {
        var returnable: [WidgetInfo] = []
        for path in installedWidgetsPaths {
            if var info = try? WidgetInfo(path: path) {
                info.loaded = loadedWidgets.contains(where: {
                    guard let clss = object_getClass($0) else {
                        return false
                    }
                    return NSStringFromClass(clss) == info.className
                })
                returnable.append(info)
            }
        }
        return returnable.sorted(by: { $0.name < $1.name })
    }
    
    /// Load widgets from widgets directory
    public func loadInstalledWidget(_ completion: ([PKWidget]) -> Void) {
        self.loadedWidgets.removeAll()
        for widgetBundleURL in installedWidgetsPaths {
            try? loadWidgetAt(path: widgetBundleURL)
        }
        completion(loadedWidgets)
    }
    
}

// MARK: Utilities
extension WidgetsDispatcher {
    
    private func loadWidgetAt(path: URL) throws {
		if let widgetBundle = Bundle(url: path) {
            if let clss = widgetBundle.principalClass as? PKWidget.Type {
				self.loadedWidgets.append(clss.init())
                return
            }
        }
        throw NSError(domain: "WidgetDispatcher:loadWidgetAt", code: 999, userInfo: ["description": "Can't load widget at: \"\(path.absoluteString)\""])
    }
    
    internal func installWidget(at path: URL?) throws {
        guard let path = path else {
            throw NSError(domain: "WidgetDispatcher:installWidget", code: 404, userInfo: ["description": "Can't read widget path."])
        }
        try installWidget(at: path.path, name: path.lastPathComponent)
    }
    
    internal func installWidget(at directory: String?, name: String?) throws {
        guard let directory = directory, let name = name else {
            throw NSError(domain: "WidgetDispatcher:installWidget", code: 404, userInfo: ["description": "Can't read widgets bundle URL."])
        }
		let path = "\(widgetsPath)/\(name)"
		if fileExists(at: path, isDirectory: true) {
			try FileManager.default.moveItem(atPath: path, toPath: "\(path).tmp")
		}
		defer {
			if fileExists(at: path, isDirectory: true) {
				Bundle(path: "\(path).tmp")?.unload()
				try? FileManager.default.removeItem(atPath: "\(path).tmp")
			}else {
				try? FileManager.default.moveItem(atPath: "\(path).tmp", toPath: path)
			}
		}
		do {
			if configuration.shouldDeleteAfterInstall {
				try FileManager.default.moveItem(atPath: directory, toPath: path)
			}else {
				try FileManager.default.copyItem(atPath: directory, toPath: path)
			}
			async { [weak self, path] in
				try? self?.loadWidgetAt(path: URL(fileURLWithPath: path))
			}
		} catch {
			throw error
		}
    }
    
    internal func removeWidget(withName name: String?) throws {
        guard let widgetPath = getWidgetPath(for: name) else {
            throw NSError(domain: "WidgetDispatcher:removeWidget", code: 500, userInfo: ["description": "Invalid passed name: `\(name ?? "nil")`"])
        }
        try removeWidget(atPath: widgetPath)
    }
    
    internal func removeWidget(atPath path: String?) throws {
        guard let widgetPath = path, fileExists(at: widgetPath, isDirectory: true) else {
            throw NSError(domain: "WidgetDispatcher:removeWidget", code: 404, userInfo: ["description": "Can't find bundle for widget at path: \"\(path ?? "Unknown")\""])
        }
        try FileManager.default.removeItem(atPath: widgetPath)
    }
    
}
