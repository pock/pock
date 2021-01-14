//
//  WidgetInfo.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import Foundation

public struct WidgetInfo {
    /// Data
    let path:      URL?
    let id:        String
    let name:      String
    let version:   String
	let build:	   String
    let author:    String
    let className: String
    var loaded:    Bool
    
    /// Preference
    let preferenceClass: AnyClass?
    var hasPreferences: Bool {
        return preferenceClass != nil
    }
    
    /// Load info for widget at given path.
    public init(path: URL) throws {
        if let widgetBundle = Bundle(path: path.path), let className = widgetBundle.object(forInfoDictionaryKey: "NSPrincipalClass") as? String {
            /// Data
            self.path      = path
            self.id        = widgetBundle.object(forInfoDictionaryKey: "CFBundleIdentifier")         as? String ?? "Unknown"
            self.name      = widgetBundle.object(forInfoDictionaryKey: "CFBundleName")               as? String ?? "Unknown"
            self.version   = widgetBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
            self.author    = widgetBundle.object(forInfoDictionaryKey: "PKWidgetAuthor")             as? String ?? "Unknown"
			if let build = widgetBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
				self.build = build == "1" ? "" : "-\(build)"
			}else {
				self.build = ""
			}
            self.className = className
            self.loaded  = false
            /// Preference
            if let preferenceClassName = widgetBundle.object(forInfoDictionaryKey: "PKWidgetPreferenceClass") as? String {
                self.preferenceClass = NSClassFromString(preferenceClassName)
            }else {
                self.preferenceClass = nil
            }
            return
        }
        throw NSError(domain: "WidgetInfo:init", code: 999, userInfo: ["description": "Can't load widget at: \"\(path.absoluteString)\""])
    }
    
}

