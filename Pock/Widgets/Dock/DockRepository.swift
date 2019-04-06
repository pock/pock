//
//  DockRepository.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

protocol DockDelegate {
    func didUpdateRunningApps(apps: [DockItem])
}

class DockRepository {
    
    /// Core
    private let delegate: DockDelegate
    
    /// Running applications
    private var runningApplications: [DockItem] = []
    
    /// Init
    init(delegate: DockDelegate) {
        self.delegate = delegate
        self.registerForNotifications()
    }
    
    /// Deinit
    deinit {
        self.unregisterForNotifications()
    }
    
    /// Reload
    @objc public func reload(_ notification: NSNotification?) {
        // TODO: Analyze notification to add/edit/remove specific item instead of all dataset.
        loadRunningApplications()
    }
    
    /// Unregister from notification
    private func unregisterForNotifications() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    /// Register for notification
    private func registerForNotifications() {
//        NSWorkspace.shared.notificationCenter.addObserver(self,
//                                                          selector: #selector(displayIconsInDockScrollView(_:)),
//                                                          name: NSWorkspace.willLaunchApplicationNotification,
//                                                          object: nil)
//
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reload(_:)),
                                                          name: NSWorkspace.didLaunchApplicationNotification,
                                                          object: nil)
//
//        NSWorkspace.shared.notificationCenter.addObserver(self,
//                                                          selector: #selector(displayIconsInDockScrollView(_:)),
//                                                          name: NSWorkspace.didActivateApplicationNotification,
//                                                          object: nil)
//
//        NSWorkspace.shared.notificationCenter.addObserver(self,
//                                                          selector: #selector(displayIconsInDockScrollView(_:)),
//                                                          name: NSWorkspace.didDeactivateApplicationNotification,
//                                                          object: nil)
//
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reload(_:)),
                                                          name: NSWorkspace.didTerminateApplicationNotification,
                                                          object: nil)
//
//        NSWorkspace.shared.notificationCenter.addObserver(self,
//                                                          selector: #selector(self.setupNotificationBadgeRefreshTimer),
//                                                          name: .didChangeNotificationBadgeRefreshRate,
//                                                          object: nil)
    }
    
    /// Load running applications
    private func loadRunningApplications() {
        runningApplications.removeAll(where: { !NSWorkspace.shared.runningApplications.map({ $0.bundleIdentifier }).contains($0.bundleIdentifier) })
        var apps: [DockItem] = []
        for app in NSWorkspace.shared.runningApplications {
            /// Check for policy
            guard app.activationPolicy == .regular, let id = app.bundleIdentifier else { continue }
            /// Check if elements already exists
            if let dockItem = runningApplications.first(where: { $0.bundleIdentifier == id }) {
                dockItem.isLaunching = !app.isFinishedLaunching
            }else {
                guard   let localizedName = app.localizedName,
                        let bundleURL     = app.bundleURL,
                        let icon          = app.icon else { continue }
                apps.append(DockItem(id, name: localizedName, path: bundleURL, icon: icon, pid_t: app.processIdentifier, launching: !app.isFinishedLaunching))
            }
        }
        delegate.didUpdateRunningApps(apps: apps)
    }
    
}
