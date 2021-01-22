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
    static let widgets_manager_list    = Preferences.PaneIdentifier("widgets_manager_list")
    static let widgets_manager_install = Preferences.PaneIdentifier("widgets_manager_install")
}

extension NSNotification.Name {
    static let shouldReloadPock             = NSNotification.Name("shouldReloadPock")
    static let shouldEnableAutomaticUpdates = NSNotification.Name("shouldEnableAutomaticUpdates")
}

extension Defaults.Keys {
	/// General
	static let didShowOnboardScreen	  = Defaults.Key<Bool>("didShowOnboardScreen",	 default: false)
    static let enableAutomaticUpdates = Defaults.Key<Bool>("enableAutomaticUpdates", default: false)
	static let allowBlankTouchBar	  = Defaults.Key<Bool>("allowBlankTouchBar",	 default: false)
	/// Mouse support
	static let enableMouseSupport    = Defaults.Key<Bool>("enableMouseSupport",    default: true)
	static let showMouseTrackingArea = Defaults.Key<Bool>("showMouseTrackingArea", default: false)
	/// Presentation mode
	static let disableControlStrip		 = Defaults.Key<Bool>("disableControlStrip", default: true)
	static let preferredPresentationMode = Defaults.Key<String?>("preferredPresentationMode", default: nil)
}
