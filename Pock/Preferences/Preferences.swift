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

// MARK: Preferences
extension Preferences.PaneIdentifier {
    static let general = Preferences.PaneIdentifier("general")
}

// MARK: Widgets Manager
extension Preferences.PaneIdentifier {
    static let widgets_manager_list = Preferences.PaneIdentifier("widgets_manager_list")
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

extension Defaults.Keys {
    static let hideControlStrip       = Defaults.Key<Bool?>("hideControlStrip",      default: true)
    static let enableAutomaticUpdates = Defaults.Key<Bool>("enableAutomaticUpdates", default: false)
}
