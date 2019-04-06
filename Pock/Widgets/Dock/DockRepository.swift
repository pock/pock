//
//  DockRepository.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

protocol DockDelegate {
    func didUpdate(apps: [DockItem])
    func didUpdateBadge(for apps: [DockItem])
}

class DockRepository {
    
    /// Core
    private let delegate: DockDelegate
    private var notificationBadgeRefreshTimer: Timer!
    
    /// Running applications
    public var allItems: [DockItem] {
        return runningApplications + persistentItems
    }
    private var runningApplications: [DockItem] = []
    private var persistentItems:     [DockItem] = []
    
    /// Init
    init(delegate: DockDelegate) {
        self.delegate = delegate
        self.registerForNotifications()
        self.setupNotificationBadgeRefreshTimer()
    }
    
    /// Deinit
    deinit {
        self.unregisterForNotifications()
    }
    
    /// Reload
    @objc public func reload(_ notification: NSNotification?) {
        // TODO: Analyze notification to add/edit/remove specific item instead of all dataset.
        loadRunningApplications()
        loadNotificationBadges()
    }
    
    /// Unregister from notification
    private func unregisterForNotifications() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    /// Register for notification
    private func registerForNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reload(_:)),
                                                          name: NSWorkspace.willLaunchApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reload(_:)),
                                                          name: NSWorkspace.didLaunchApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reload(_:)),
                                                          name: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reload(_:)),
                                                          name: NSWorkspace.didDeactivateApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reload(_:)),
                                                          name: NSWorkspace.didTerminateApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.setupNotificationBadgeRefreshTimer),
                                                          name: .didChangeNotificationBadgeRefreshRate,
                                                          object: nil)
    }
    
    /// Load running applications
    private func loadRunningApplications() {
        runningApplications.removeAll(where: { item in
            return !NSWorkspace.shared.runningApplications.contains(where: { app in
                app.bundleIdentifier == item.bundleIdentifier
            })
        })
        for app in NSWorkspace.shared.runningApplications {
            if let item = runningApplications.first(where: { $0.bundleIdentifier == app.bundleIdentifier }) {
                item.name        = app.localizedName ?? item.name
                item.icon        = app.icon ?? item.icon
                item.pid_t       = app.processIdentifier
                item.isLaunching = !app.isFinishedLaunching
            }else {
                /// Check for policy
                guard app.activationPolicy == .regular, let id = app.bundleIdentifier else { continue }
                guard   let localizedName = app.localizedName,
                        let bundleURL     = app.bundleURL,
                        let icon          = app.icon else { continue }
                
                let item = DockItem(0, id, name: localizedName, path: bundleURL, icon: icon, pid_t: app.processIdentifier, launching: !app.isFinishedLaunching)
                runningApplications.append(item)
            }
        }
        delegate.didUpdate(apps: Array(runningApplications))
    }
    
    /// Load notification badges
    private func loadNotificationBadges() {
        for item in allItems {
            item.badge = PockDockHelper.sharedInstance()?.getBadgeCountForItem(withName: item.name)
        }
        let apps = allItems.filter({ $0.hasBadge })
        delegate.didUpdateBadge(for: Array(apps))
    }
    
}

extension DockRepository {
    
    /// Update notification badge refresh timer
    @objc private func setupNotificationBadgeRefreshTimer() {
        /// Get refresh rate
        let refreshRate = defaults[.notificationBadgeRefreshInterval]
        /// Invalidate last timer
        self.notificationBadgeRefreshTimer?.invalidate()
        /// Set timer
        self.notificationBadgeRefreshTimer = Timer.scheduledTimer(withTimeInterval: refreshRate.rawValue, repeats: true, block: {  [weak self] _ in
            /// Log
            NSLog("[Pock]: Refreshing notification badge... (rate: %@)", refreshRate.toString())
            /// Reload badge and running dot
            DispatchQueue.main.async { [weak self] in
                self?.loadNotificationBadges()
            }
        })
    }
    
}
