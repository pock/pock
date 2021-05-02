//
//  Preferences.swift
//  Pock
//
//  Created by Pierluigi Galdi on 02/05/21.
//

import Foundation

extension NSNotification.Name {
	static let shouldReloadPock = NSNotification.Name("shouldReloadPock")
	static let shouldEnableAutomaticUpdates = NSNotification.Name("shouldEnableAutomaticUpdates")
}

internal struct Preferences {
	internal enum Keys: String {
		case allowBlankTouchBar
		case launchAtLogin
		case mouseSupportEnabled
		case showTrackingArea
		case checkForUpdatesOnceADay
	}
	static subscript<T>(_ key: Keys) -> T {
		get {
			guard let value = UserDefaults.standard.value(forKey: key.rawValue) as? T else {
				// swiftlint:disable force_cast
				switch key {
				case .allowBlankTouchBar:
					return true as! T
				case .launchAtLogin:
					return false as! T
				case .mouseSupportEnabled:
					return true as! T
				case .showTrackingArea:
					return false as! T
				case .checkForUpdatesOnceADay:
					return false as! T
				}
				// swiftlint:enable force_cast
			}
			return value
		}
		set {
			UserDefaults.standard.setValue(newValue, forKey: key.rawValue)
		}
	}
}
