//
//  Preferences.swift
//  Pock
//
//  Created by Pierluigi Galdi on 02/05/21.
//

import Foundation
import ServiceManagement

extension NSNotification.Name {
	static let shouldReloadPock = NSNotification.Name("shouldReloadPock")
	static let shouldEnableAutomaticUpdates = NSNotification.Name("shouldEnableAutomaticUpdates")
	static let shouldUpdateMenuBarIconVisibility = NSNotification.Name("shouldUpdateMenuBarIconVisibility")
}

internal enum LayoutStyle: String {
	case fullWidth, withControlStrip
	var presentationMode: PresentationMode {
		switch self {
		case .withControlStrip:
			return .appWithControlStrip
		case .fullWidth:
			return .app
		}
	}
	var title: String {
		switch self {
		case .withControlStrip:
			return "layout-style.show-control-strip".localized
		case .fullWidth:
			return "layout-style.full-width".localized
		}
	}
}

internal struct Preferences {
	internal enum Keys: String {
		case allowBlankTouchBar
		case launchAtLogin
		case layoutStyle
		case mouseSupportEnabled
		case showTrackingArea
		case checkForUpdatesOnceADay
		case userDefinedPresentationMode
		case didShowOnBoard
        case showDebugConsoleOnLaunch
		case doubleControlShortcutEnabled
		case showMenuBarIcon
		case launchInProgress
	}
	static subscript<T>(_ key: Keys) -> T {
        get {
            // swiftlint:disable force_cast
            if key == .launchAtLogin {
                return LaunchAtLogin.isEnabled as! T
            }
            guard let value = UserDefaults.standard.value(forKey: key.rawValue) as? T else {
                if T.self == LayoutStyle.self, let raw = UserDefaults.standard.value(forKey: key.rawValue) as? String {
                    return LayoutStyle(rawValue: raw) as! T
                }
                if T.self == PresentationMode.self, let raw = UserDefaults.standard.value(forKey: key.rawValue) as? String {
                    return PresentationMode(rawValue: raw) as! T
                }
                switch key {
                case .allowBlankTouchBar:
                    return false as! T
                case .launchAtLogin:
                    fatalError("[Pock][Internal-Error][Preferences.launchAtLogin]: Execution should not reach this point.")
                case .layoutStyle:
                    return LayoutStyle.withControlStrip as! T
                case .mouseSupportEnabled:
                    return true as! T
                case .showTrackingArea:
                    return false as! T
                case .checkForUpdatesOnceADay:
                    return false as! T
                case .userDefinedPresentationMode:
                    return PresentationMode.undefined as! T
                case .didShowOnBoard:
                    return false as! T
                case .showDebugConsoleOnLaunch:
                    return false as! T
                case .doubleControlShortcutEnabled:
                    return true as! T
                case .showMenuBarIcon:
                    return true as! T
                case .launchInProgress:
                    return false as! T
                }
            }
            return value
            // swiftlint:enable force_cast
        }
		set {
			if key == .launchAtLogin {
				if let boolValue = newValue as? Bool {
					LaunchAtLogin.isEnabled = boolValue
				}
			} else {
				UserDefaults.standard.setValue(newValue, forKey: key.rawValue)
			}
		}
	}
}

// MARK: Launch at login
private enum LaunchAtLogin {
	/// `LSSharedFileList` is deprecated and silently stopped working on macOS 13+, use `SMAppService` there.
	static var isEnabled: Bool {
		get {
			if #available(macOS 13.0, *) {
				return SMAppService.mainApp.status == .enabled
			}
			return LoginServiceKit().existsLoginItem(for: .main)
		}
		set {
			if #available(macOS 13.0, *) {
				do {
					if newValue {
						try SMAppService.mainApp.register()
						/// The user may have to allow Pock in System Settings → Login Items
						if SMAppService.mainApp.status == .requiresApproval {
							SMAppService.openSystemSettingsLoginItems()
						}
					} else {
						try SMAppService.mainApp.unregister()
					}
				} catch {
					Roger.error("[Preferences][LaunchAtLogin]: \(error.localizedDescription)")
				}
				/// Clean up legacy login item, if any
				if newValue == false {
					LoginServiceKit().removeLoginItem(for: .main)
				}
				return
			}
			if newValue {
				LoginServiceKit().addLoginItem(for: .main)
			} else {
				LoginServiceKit().removeLoginItem(for: .main)
			}
		}
	}
}
