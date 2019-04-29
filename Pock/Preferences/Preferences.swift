//
//  Preferences.swift
//  Pock
//
//  Created by Pierluigi Galdi on 12/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

let isProd: Bool = true

extension NSNotification.Name {
    static let didChangeNotificationBadgeRefreshRate = NSNotification.Name("didSelectNotificationBadgeRefreshRate")
    static let shouldReloadPock                      = NSNotification.Name("shouldReloadPock")
    static let shouldReloadDock                      = NSNotification.Name("shouldReloadDock")
    static let shouldReloadPersistentItems           = NSNotification.Name("shouldReloadPersistentItems")
    static let shouldEnableAutomaticUpdates          = NSNotification.Name("shouldEnableAutomaticUpdates")
}

enum NotificationBadgeRefreshRateKeys: Double, Codable, CaseIterable {
    case instantly      = 0.25
    case oneSecond      = 1
    case fiveSeconds    = 5
    case tenSeconds     = 10
    case thirtySeconds  = 30
    case oneMinute      = 60
    case threeMinutes   = 180
    
    func toString() -> String {
        switch self {
        case .instantly:
            return "Instantly"
        case .oneSecond:
            return "1 second"
        case .fiveSeconds:
            return "5 seconds"
        case .tenSeconds:
            return "10 seconds"
        case .thirtySeconds:
            return "30 seconds"
        case .oneMinute:
            return "1 minute"
        case .threeMinutes:
            return "3 minutes"
        }
    }
}

extension Defaults.Keys {
    static let launchAtLogin                    = Defaults.Key<Bool>("launchAtLogin",          default: false)
    static let notificationBadgeRefreshInterval = Defaults.Key<NotificationBadgeRefreshRateKeys>("notificationBadgeRefreshInterval", default: .tenSeconds)
    static let hideControlStrip                 = Defaults.Key<Bool>("hideControlStrip",       default: false)
    static let hideFinder                       = Defaults.Key<Bool>("hideFinder",             default: false)
    static let hideTrash                        = Defaults.Key<Bool>("hideTrash",              default: false)
    static let hidePersistentItems              = Defaults.Key<Bool>("hidePersistentItems",    default: false)
    static let enableAutomaticUpdates           = Defaults.Key<Bool>("enableAutomaticUpdates", default: false)
}
