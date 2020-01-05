//
//  WidgetsDispatcherr.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/11/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import PockKit

internal struct WidgetInfo {
    let path:    URL?
    let id:      String
    let name:    String
    let version: String
    let author:  String
    let loaded:  Bool
}

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
            if let info = try? loadInfoForWidgetAt(path: path) {
                returnable.append(info)
            }
        }
        return returnable.sorted(by: { $0.name < $1.name })
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
    
    private func loadInfoForWidgetAt(path: URL) throws -> WidgetInfo {
        if let widgetBundle = Bundle(url: path) {
            let id      = widgetBundle.object(forInfoDictionaryKey: "CFBundleIdentifier")         as? String
            let name    = widgetBundle.object(forInfoDictionaryKey: "CFBundleName")               as? String
            let version = widgetBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            let author  = widgetBundle.object(forInfoDictionaryKey: "PKWidgetAuthor")             as? String
            let clss    = widgetBundle.object(forInfoDictionaryKey: "NSPrincipalClass")           as? String
            return WidgetInfo(
                path:    path,
                id:      id      ?? "Unknown",
                name:    name    ?? "Unknown",
                version: version ?? "Unknown",
                author:  author  ?? "Unknown",
                loaded:  loadedWidgets.values.contains(where: {
                    NSStringFromClass($0) == clss
                })
            )
        }
        throw NSError(domain: "WidgetDispatcher:loadInfoForWidgetAt", code: 999, userInfo: ["description": "Can't load widget at: \"\(path.absoluteString)\""])
    }
    
    private func loadWidgetAt(path: URL) throws {
        if let widgetBundle = Bundle(url: path), widgetBundle.load() {
            if let clss = widgetBundle.principalClass as? PKWidget.Type {
                var plugin: PKWidget? = clss.init()
                self.loadedWidgets[plugin!.identifier] = clss
                plugin = nil
                return
            }
        }
        throw NSError(domain: "WidgetDispatcher:loadWidgetAt", code: 999, userInfo: ["description": "Can't load widget at: \"\(path.absoluteString)\""])
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
