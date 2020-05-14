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
    static let general = Identifier("general")
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

extension Defaults.Keys {
    static let hideControlStrip       = Defaults.Key<Bool?>("hideControlStrip",      default: true)
    static let enableAutomaticUpdates = Defaults.Key<Bool>("enableAutomaticUpdates", default: false)
}
