//
//  PKWidgetInfo.swift
//  Pock
//
//  Created by Pierluigi Galdi on 30/04/21.
//

import Foundation

public struct PKWidgetInfo: Equatable {
	
	public enum BundleKeys: String {
		case principalClass = "NSPrincipalClass"
		case bundleIdentifier = "CFBundleIdentifier"
		case bundleName = "CFBundleName"
        case bundleDisplayName = "CFBundleDisplayName"
		case bundleVersion = "CFBundleShortVersionString"
		case widgetAuthor = "PKWidgetAuthor"
		case bundleBuild = "CFBundleVersion"
		case widgetPreferenceClass = "PKWidgetPreferenceClass"
	}
	
	/// Compare if two widgets are equal based on their `bundleIdentifier`
	public static func == (lhs: PKWidgetInfo, rhs: PKWidgetInfo) -> Bool {
		return lhs.bundleIdentifier == rhs.bundleIdentifier
	}
	
	// MARK: Data
	let path: URL
	let bundleIdentifier: String
	let principalClass: AnyClass?
	let name: String
	let author: String
	let version: String
	let build: String?
	let loaded: Bool
	
	var fullVersion: String {
		if let build = build {
			return "\(version)-\(build)"
		}
		return version
	}
	
	// MARK: Preferences
	let preferencesClass: AnyClass?
	var hasPreferences: Bool {
		return preferencesClass != nil
	}
	
	// MARK: Load
	
	/// Load widget's info for bundle at given path
	public init(path: URL) throws {
		guard let bundle = Bundle(path: path.path),
			  let bundleIdentifier: String = bundle[.bundleIdentifier],
			  let principalClass = bundle.principalClass,
              let name: String = bundle[.bundleDisplayName] ?? bundle[.bundleName],
			  let author: String = bundle[.widgetAuthor],
			  let version: String = bundle[.bundleVersion] else {
			throw NSError(domain: "PKWidgetInfo:init", code: -1, userInfo: ["description": "Can't load widget at: \"\(path.absoluteString)\""])
		}
		self.path = path
		self.bundleIdentifier = bundleIdentifier
		self.principalClass = principalClass
		self.name = name
		self.author = author
		self.version = version
		if let build: String = bundle[.bundleBuild] {
			self.build = build == "1" ? nil : build
		} else {
			self.build = nil
		}
		self.loaded = bundle.isLoaded
		/// Preferences
		if let preferencesClassName: String = bundle[.widgetPreferenceClass] {
			self.preferencesClass = NSClassFromString(preferencesClassName)
		} else {
			self.preferencesClass = nil
		}
	}
    
    public init(unloadableWidgetAtPath path: URL) throws {
        let infoFile = path.appendingPathComponent("Contents", isDirectory: true).appendingPathComponent("Info").appendingPathExtension("plist")
        guard let infoDict = NSDictionary(contentsOf: infoFile), let bundleIdentifier: String = infoDict[.bundleIdentifier] else {
            throw NSError(domain: "PKWidgetInfo:init", code: -1, userInfo: ["description": "Can't load widget at: \"\(path.absoluteString)\""])
        }
        self.path = path
        self.bundleIdentifier = bundleIdentifier
        self.principalClass = nil
        self.name = infoDict[.bundleDisplayName] ?? infoDict[.bundleName] ?? "Unknown"
        self.author = infoDict[.widgetAuthor] ?? "Unknown"
        self.version = infoDict[.bundleVersion] ?? "--"
        if let build: String = infoDict[.bundleBuild] {
            self.build = build == "1" ? nil : build
        } else {
            self.build = nil
        }
        self.loaded = false
        /// Preferences
        self.preferencesClass = nil
    }
	
}

extension Bundle {
	fileprivate subscript<T>(_ key: PKWidgetInfo.BundleKeys) -> T? {
		return object(forInfoDictionaryKey: key.rawValue) as? T
	}
}

extension NSDictionary {
    fileprivate subscript<T>(_ key: PKWidgetInfo.BundleKeys, type: T.Type = T.self) -> T? {
        return value(forKey: key.rawValue) as? T
    }
}
