//
//  PKWidgetInfo.swift
//  Pock
//
//  Created by Pierluigi Galdi on 30/04/21.
//

import Foundation

public struct PKWidgetInfo: Equatable {
	
	fileprivate enum BundleKeys: String {
		case principalClass = "NSPrincipalClass"
		case bundleIdentifier = "CFBundleIdentifier"
		case bundleName = "CFBundleName"
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
	let principalClass: AnyClass
	let name: String
	let author: String
	let version: String
	let build: String
	let loaded: Bool
	
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
			  let name: String = bundle[.bundleName],
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
			self.build = build == "1" ? "" : "-\(build)"
		} else {
			self.build = ""
		}
		self.loaded = bundle.isLoaded
		/// Preferences
		if let preferencesClassName: String = bundle[.widgetPreferenceClass] {
			self.preferencesClass = NSClassFromString(preferencesClassName)
		} else {
			self.preferencesClass = nil
		}
	}
	
}

extension Bundle {
	fileprivate subscript<T>(_ key: PKWidgetInfo.BundleKeys) -> T? {
		return object(forInfoDictionaryKey: key.rawValue) as? T
	}
}
