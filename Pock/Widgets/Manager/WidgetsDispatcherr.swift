//
//  WidgetsDispatcherr.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/11/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import PockKit

public final class WidgetsDispatcher {
    
    /// Configuration
    public struct Configuration {
        let shouldDeleteAfterInstall: Bool
        static let `default`: Configuration = Configuration(shouldDeleteAfterInstall: true)
    }
    
    /// Singleton
    public static let `default`: WidgetsDispatcher = WidgetsDispatcher(configuration: .default)
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Core
    private var configuration: Configuration
    
    /// Data
    public private(set) var loadedWidgets: [NSTouchBarItem.Identifier: PKWidget.Type] = [:]
    
    /// Getters
    private var applicationSupportPockFolder: String {
        return FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Pock"
    }
    private var widgetsPath: String {
        return applicationSupportPockFolder + "/Widgets"
    }
    
    public func clearLoadedWidgets() {
        loadedWidgets = [:]
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
        return widgetsPath + "/\(name).pock"
    }
    
    public var installedWidgetsPaths: [URL] {
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
    
    /// Load widgets from widgets directory
    public func loadInstalledWidget(_ completion: ([NSTouchBarItem.Identifier]) -> Void) {
        self.loadedWidgets.removeAll()
        for widgetBundleURL in installedWidgetsPaths {
            try? loadWidgetAt(path: widgetBundleURL)
        }
        completion(Array(loadedWidgets.keys))
    }
    
}

// MARK: Utilities
extension WidgetsDispatcher {
    
    internal func loadWidgetAt(path: URL) throws {
        if let widgetBundle = Bundle(url: path), widgetBundle.load() {
            if let clss = widgetBundle.principalClass as? PKWidget.Type {
                var plugin: PKWidget? = clss.init()
                self.loadedWidgets[plugin!.identifier] = clss
                plugin = nil
                return
            }
        }
        throw NSError(domain: "WidgetDispatcher:loadWidget", code: 999, userInfo: ["description": "Can't load widget at: \"\(path.absoluteString)\""])
    }
    
    internal func installWidget(at directory: String?) throws {
        guard let directory = directory else {
            throw NSError(domain: "WidgetDispatcher:installWidget", code: 404, userInfo: ["description": "Can't read widgets bundle URL."])
        }
        if configuration.shouldDeleteAfterInstall {
            try FileManager.default.moveItem(atPath: directory, toPath: widgetsPath)
        }else {
            try FileManager.default.copyItem(atPath: directory, toPath: widgetsPath)
        }
    }
    
    internal func removeWidget(withName name: String?) throws {
        guard let _name = name, let widgetPath = getWidgetPath(for: name) else {
            throw NSError(domain: "WidgetDispatcher:removeWidget", code: 500, userInfo: ["description": "Invalid passed name: `\(name ?? "nil")`"])
        }
        guard fileExists(at: widgetPath, isDirectory: true) else {
            throw NSError(domain: "WidgetDispatcher:removeWidget", code: 404, userInfo: ["description": "Can't find bundle for widget: \"\(_name)\""])
        }
        try FileManager.default.removeItem(atPath: widgetPath)
    }
    
    @discardableResult
    internal func updateWidget(withName name: String?, with newItemPath: String?) throws -> URL? {
        guard let name = name, let widgetPath = getWidgetPath(for: name), let newItemPath = newItemPath else {
            throw NSError(domain: "WidgetDispatcher:removeWidget", code: 500, userInfo: ["description": "Invalid passed name: `nil`"])
        }
        let pathURL    = URL(fileURLWithPath: widgetPath)
        let newItemURL = URL(fileURLWithPath: newItemPath)
        return try FileManager.default.replaceItemAt(pathURL, withItemAt: newItemURL)
    }
    
}
