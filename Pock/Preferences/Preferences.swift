//
//  Preferences.swift
//  Pock
//
//  Created by Pierluigi Galdi on 12/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Preferences
import Defaults

let isProd: Bool = false

// MARK: Preferences
extension PreferencePane.Identifier {
    static let general                 = Identifier("general")
    static let dock_widget             = Identifier("dock_widget")
    static let controler_center_widget = Identifier("control_center_widget")
}

// MARK: Widgets Manager
extension PreferencePane.Identifier {
    static let widgets_manager_list = Identifier("widgets_manager_list")
}

extension NSNotification.Name {
    static let didChangeNotificationBadgeRefreshRate = NSNotification.Name("didSelectNotificationBadgeRefreshRate")
    static let shouldReloadPock                      = NSNotification.Name("shouldReloadPock")
    static let shouldReloadControlCenterWidget       = NSNotification.Name("shouldReloadControlCenterWidget")
    static let shouldReloadDock                      = NSNotification.Name("shouldReloadDock")
    static let shouldReloadDockLayout                = NSNotification.Name("shouldReloadDockLayout")
    static let shouldReloadPersistentItems           = NSNotification.Name("shouldReloadPersistentItems")
    static let shouldEnableAutomaticUpdates          = NSNotification.Name("shouldEnableAutomaticUpdates")
    static let didChangeNowPlayingWidgetStyle        = NSNotification.Name("didChangeNowPlayingWidgetStyle")
}

enum NotificationBadgeRefreshRateKeys: Double, Codable, CaseIterable {
    case never          = -1
    case instantly      = 0.25
    case oneSecond      = 1
    case fiveSeconds    = 5
    case tenSeconds     = 10
    case thirtySeconds  = 30
    case oneMinute      = 60
    case threeMinutes   = 180
    
    func toString() -> String {
        switch self {
        case .never:
            return "Never".localized
        case .instantly:
            return "Instantly".localized
        case .oneSecond:
            return "1 second".localized
        case .fiveSeconds:
            return "5 seconds".localized
        case .tenSeconds:
            return "10 seconds".localized
        case .thirtySeconds:
            return "30 seconds".localized
        case .oneMinute:
            return "1 minute".localized
        case .threeMinutes:
            return "3 minutes".localized
        }
    }
}

enum AppExposeSettings : String, Codable, CaseIterable {
    case never, ifNeeded, always

    var title: String {
        switch self {
        case .never: return "Never".localized
        case .ifNeeded: return "More Than 1 Window".localized
        case .always: return "Always".localized
        }
    }
}

extension Defaults.Keys {
    static let hideControlStrip                 = Defaults.Key<Bool?>("hideControlStrip",      default: true)
    static let enableAutomaticUpdates           = Defaults.Key<Bool>("enableAutomaticUpdates", default: false)
    /// Dock widget
    static let notificationBadgeRefreshInterval = Defaults.Key<NotificationBadgeRefreshRateKeys>("notificationBadgeRefreshInterval", default: .tenSeconds)
    static let appExposeSettings                = Defaults.Key<AppExposeSettings>("appExposeSettings", default: .ifNeeded)
    static let itemSpacing                      = Defaults.Key<Int>("itemSpacing",             default: 8)
    static let hideFinder                       = Defaults.Key<Bool>("hideFinder",             default: false)
    static let showOnlyRunningApps              = Defaults.Key<Bool>("showOnlyRunningApps",    default: false)
    static let hideTrash                        = Defaults.Key<Bool>("hideTrash",              default: false)
    static let hidePersistentItems              = Defaults.Key<Bool>("hidePersistentItems",    default: false)
    static let openFinderInsidePock             = Defaults.Key<Bool>("openFinderInsidePock",   default: true)
}
