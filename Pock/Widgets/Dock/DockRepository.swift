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
    func didUpdate(items: [DockItem])
    func didUpdateBadge(for apps: [DockItem])
    func didUpdateRunningState(for apps: [DockItem])
}

class DockRepository {
    
    /// Core
    private var fileMonitor: FileMonitor?
    private let delegate: DockDelegate
    private var notificationBadgeRefreshTimer: Timer!
    
    /// Running applications
    public  var dockItems:       [DockItem] = []
    private var runningItems:    [DockItem] = []
    private var persistentApps:  [DockItem] = []
    public  var persistentItems: [DockItem] = []
    
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
        dockItems.removeAll()
        runningItems.removeAll()
        persistentApps.removeAll()
        persistentItems.removeAll()
        loadPersistentApps()
        loadRunningApplications(notification)
        loadPersistentItems()
        delegate.didUpdate(apps: dockItems)
        updateNotificationBadges()
        updateRunningState()
    }
    
    /// Unregister from notification
    private func unregisterForNotifications() {
        fileMonitor = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    /// Register for notification
    private func registerForNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(loadRunningApplications(_:)),
                                                          name: NSWorkspace.willLaunchApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(loadRunningApplications(_:)),
                                                          name: NSWorkspace.didLaunchApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(loadRunningApplications(_:)),
                                                          name: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(loadRunningApplications(_:)),
                                                          name: NSWorkspace.didDeactivateApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(loadRunningApplications(_:)),
                                                          name: NSWorkspace.didTerminateApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reload(_:)),
                                                          name: .shouldReloadDock,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.setupNotificationBadgeRefreshTimer),
                                                          name: .didChangeNotificationBadgeRefreshRate,
                                                          object: nil)
        
        fileMonitor = FileMonitor(paths: [Constants.trashPath, Constants.dockPlist], delegate: self)
    }
    
    /// Check if item can be removed
    private func canRemove(item: DockItem) -> Bool {
        return  !runningItems.contains(item) && !persistentApps.contains(item)
    }
    
    /// Load running applications
    @objc private func loadRunningApplications(_ notification: NSNotification?) {
        dockItems.removeAll(where: { canRemove(item: $0) })
        runningItems.removeAll()
        for app in NSWorkspace.shared.runningApplications {
            if let item = dockItems.first(where: { $0.bundleIdentifier == app.bundleIdentifier }) {
                item.name        = app.localizedName ?? item.name
                item.icon        = app.icon ?? item.icon
                item.pid_t       = app.processIdentifier
                item.isLaunching = !app.isFinishedLaunching
                runningItems.append(item)
            }else {
                /// Check for policy
                guard app.activationPolicy == .regular, let id = app.bundleIdentifier else { continue }
                guard id != Constants.kFinderIdentifier else { continue }
                guard   let localizedName = app.localizedName,
                        let bundleURL     = app.bundleURL,
                        let icon          = app.icon else { continue }
                let item = DockItem(0, id, name: localizedName, path: bundleURL, icon: icon, pid_t: app.processIdentifier, launching: !app.isFinishedLaunching)
                runningItems.append(item)
                dockItems.append(item)
            }
        }
        delegate.didUpdate(apps: dockItems)
        updateRunningState()
    }
    
    /// Load persistent applications
    private func loadPersistentApps() {
        /// Read data from Dock plist
        guard let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.dock") else {
            NSLog("[Pock]: Can't read Dock preferences file")
            return
        }
        /// Read persistent apps array
        guard let apps = dict["persistent-apps"] as? [[String: Any]] else {
            NSLog("[Pock]: Can't get persistent apps")
            return
        }
        /// Empty array
        persistentApps.removeAll()
        /// Iterate on apps
        for (index,app) in apps.enumerated() {
            /// Get data tile
            guard let dataTile = app["tile-data"] as? [String: Any] else { NSLog("[Pock]: Can't get app tile-data"); continue }
            /// Get app's label
            guard let label = dataTile["file-label"] as? String else { NSLog("[Pock]: Can't get app label"); continue }
            /// Get app's bundle identifier
            guard let bundleIdentifier = dataTile["bundle-identifier"] as? String else { NSLog("[Pock]: Can't get app bundle identifier"); continue }
            /// Check if item already exists
            if let item = dockItems.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
                persistentApps.append(item)
            }else {
                /// Create item
                let item = DockItem(index,
                                    bundleIdentifier,
                                    name: label,
                                    path: nil,
                                    icon: getIcon(forBundleIdentifier: bundleIdentifier),
                                    pid_t: 0,
                                    launching: false)
                persistentApps.append(item)
                dockItems.append(item)
            }
        }
        if !defaults[.hideFinder] && !dockItems.contains(where: { $0.bundleIdentifier == Constants.kFinderIdentifier }) {
            let finderItem = DockItem(0, Constants.kFinderIdentifier, name: "Finder", path: nil, icon: getIcon(forBundleIdentifier: Constants.kFinderIdentifier), pid_t: 0)
            persistentApps.insert(finderItem, at: 0)
            dockItems.insert(finderItem, at: 0)
        }
    }
    
    /// Load persistent folders and files
    private func loadPersistentItems() {
        /// Read data from Dock plist
        guard let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.dock") else {
            NSLog("[Pock]: Can't read Dock preferences file")
            return
        }
        /// Read persistent apps array
        guard let apps = dict["persistent-others"] as? [[String: Any]] else {
            NSLog("[Pock]: Can't get persistent apps")
            return
        }
        /// Empty array
        persistentItems.removeAll()
        /// Iterate on apps
        for (index,app) in apps.enumerated() {
            /// Get data tile
            guard let dataTile = app["tile-data"] as? [String: Any] else { NSLog("[Pock]: Can't get file tile-data"); continue }
            /// Get app's label
            guard let label = dataTile["file-label"] as? String else { NSLog("[Pock]: Can't get file label"); continue }
            /// Get file data
            guard let fileData = dataTile["file-data"] as? [String: Any] else { NSLog("[Pock]: Can't get file data"); continue }
            /// Get app's bundle identifier
            guard let path = fileData["_CFURLString"] as? String else { NSLog("[Pock]: Can't get file path"); continue }
            /// Get other's file type.
            let tileType = app["tile-type"] as? String
            /// Create item
            let item = DockItem(index,
                                nil,
                                name: label,
                                path: URL(string: path),
                                icon: getIcon(orType: tileType),
                                launching: false,
                                persistentItem: true)
            persistentItems.append(item)
        }
        if !defaults[.hideTrash] && !persistentItems.contains(where: { $0.path?.absoluteString == Constants.trashPath }) {
            let trashType = ((try? FileManager.default.contentsOfDirectory(atPath: Constants.trashPath).isEmpty) ?? true) ? "TrashIcon" : "FullTrashIcon"
            let trashItem = DockItem(0, nil, name: "Trash", path: URL(string: "file://"+Constants.trashPath)!, icon: getIcon(orType: trashType), persistentItem: true)
            persistentItems.append(trashItem)
        }
        delegate.didUpdate(items: persistentItems)
    }
    
    /// Load running dot
    private func updateRunningState() {
        for item in dockItems {
            item.pid_t = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == item.bundleIdentifier })?.processIdentifier ?? 0
        }
        let apps = dockItems.filter({ $0.isRunning })
        delegate.didUpdateRunningState(for: apps)
    }
    
    /// Load notification badges
    private func updateNotificationBadges() {
        for item in dockItems {
            item.badge = PockDockHelper.sharedInstance()?.getBadgeCountForItem(withName: item.name)
        }
        let apps = dockItems.filter({ $0.hasBadge })
        delegate.didUpdateBadge(for: apps)
    }
    
}

extension DockRepository: FileMonitorDelegate {
    func didChange(fileMonitor: FileMonitor, paths: [String]) {
        DispatchQueue.main.async { [weak self] in
            for path in paths {
                NSLog("[Pock]: [\(type(of: fileMonitor))] # Changes in path: \(path)")
            }
            self?.reload(nil)
        }
    }
}

extension DockRepository {
    /// Get icon
    private func getIcon(forBundleIdentifier bundleIdentifier: String? = nil, orPath path: String? = nil, orType type: String? = nil) -> NSImage {
        /// Check for bundle identifier first
        if bundleIdentifier != nil {
            /// Get app's absolute path
            if let appPath = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundleIdentifier!) {
                /// Return icon
                return NSWorkspace.shared.icon(forFile: appPath)
            }
        }
        /// Then check for path
        if path != nil {
            return NSWorkspace.shared.icon(forFile: path!)
        }
        /// Last beach, manually check on type
        var genericIconPath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns"
        if type != nil {
            if type == "directory-tile" {
                genericIconPath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns"
            }else if type == "TrashIcon" || type == "FullTrashIcon" {
                genericIconPath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/\(type!).icns"
            }
        }
        /// Load image
        let genericIcon = NSImage(contentsOfFile: genericIconPath)
        /// Return icon
        return genericIcon ?? NSImage(size: .zero)
    }
    /// Launch app or open file/directory
    public func launch(bundleIdentifier: String?, completion: (Bool) -> ()) {
        /// Check if bundle identifier is valid
        guard bundleIdentifier != nil else {
            completion(false)
            return
        }
        var returnable: Bool = false
        /// Check if file path.
        if bundleIdentifier!.contains("file://") {
            /// Is path, continue as path.
            returnable = NSWorkspace.shared.openFile(bundleIdentifier!.replacingOccurrences(of: "file://", with: ""))
        }else {
            /// Launch app
            returnable = NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleIdentifier!, options: [NSWorkspace.LaunchOptions.default], additionalEventParamDescriptor: nil, launchIdentifier: nil)
        }
        /// Return status
        completion(returnable)
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
            /// NSLog("[Pock]: Refreshing notification badge... (rate: %@)", refreshRate.toString())
            /// Reload badge and running dot
            DispatchQueue.main.async { [weak self] in
                self?.updateNotificationBadges()
            }
        })
    }
    
}
