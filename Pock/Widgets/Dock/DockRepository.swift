//
//  DockRepository.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

protocol DockDelegate: class {
    func didUpdate(apps: [DockItem])
    func didUpdate(items: [DockItem])
    func didUpdateBadge(for apps: [DockItem])
    func didUpdateRunningState(for apps: [DockItem])
}

class DockRepository {
    
    /// Core
    private weak var delegate: DockDelegate?
    private var fileMonitor: FileMonitor?
    private var notificationBadgeRefreshTimer: Timer!
    private var shouldShowNotificationBadge: Bool { return defaults[.notificationBadgeRefreshInterval] != .never }
    private var showOnlyRunningApps: Bool { return defaults[.showOnlyRunningApps] }
    private var openFinderInsidePock: Bool { return defaults[.openFinderInsidePock] }
    private var dockFolderRepository: DockFolderRepository?
    
    /// Running applications
    public  var dockItems:       [DockItem] = []
    private var runningItems:    [DockItem] = []
    private var persistentApps:  [DockItem] = []
    public  var persistentItems: [DockItem] = []
    
    /// Init
    init(delegate: DockDelegate) {
        self.delegate = delegate
        self.dockFolderRepository = DockFolderRepository()
        self.registerForNotifications()
        self.setupNotificationBadgeRefreshTimer()
    }
    
    /// Deinit
    deinit {
        self.unregisterForNotifications()
        dockFolderRepository = nil
        dockItems.removeAll()
        runningItems.removeAll()
        persistentApps.removeAll()
        persistentItems.removeAll()
        if !isProd { print("[DockRepository]: Deinit Dock Repository") }
    }
    
    /// Reload
    @objc public func reloadDock(_ notification: NSNotification?) {
        dockItems.removeAll()
        runningItems.removeAll()
        persistentApps.removeAll()
        if !(showOnlyRunningApps) {
            loadPersistentApps()
        }
        loadRunningApplications(notification)
        updateRunningState(notification)
    }
    
    @objc public func reloadPersistentItems(_ notification: NSNotification?) {
        persistentItems = []
        loadPersistentItems()
    }
    
    @objc public func reload(_ notification: NSNotification?) {
        reloadDock(notification)
        reloadPersistentItems(notification)
    }
    
    /// Unregister from notification
    private func unregisterForNotifications() {
        fileMonitor = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    /// Register for notification
    private func registerForNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reloadDock(_:)),
                                                          name: NSWorkspace.willLaunchApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(updateRunningState(_:)),
                                                          name: NSWorkspace.didLaunchApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(updateRunningState(_:)),
                                                          name: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(updateRunningState(_:)),
                                                          name: NSWorkspace.didDeactivateApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reloadDock(_:)),
                                                          name: NSWorkspace.didTerminateApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reloadDock(_:)),
                                                          name: .shouldReloadDock,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(reloadPersistentItems(_:)),
                                                          name: .shouldReloadPersistentItems,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.setupNotificationBadgeRefreshTimer),
                                                          name: .didChangeNotificationBadgeRefreshRate,
                                                          object: nil)
        
        fileMonitor = FileMonitor(paths: [Constants.trashPath, Constants.dockPlist], delegate: self)
    }
    
    /// Check if item can be removed
    private func canRemove(item: DockItem) -> Bool {
        return !runningItems.contains(item) && !persistentApps.contains(item)
    }
    
    /// Load running applications
    @objc private func loadRunningApplications(_ notification: NSNotification?) {
        dockItems.removeAll(where: { canRemove(item: $0) })
        runningItems = []
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
        if !defaults[.hideFinder] && !dockItems.contains(where: { $0.bundleIdentifier == Constants.kFinderIdentifier }) {
            let finderItem = DockItem(0, Constants.kFinderIdentifier, name: "Finder", path: nil, icon: DockRepository.getIcon(forBundleIdentifier: Constants.kFinderIdentifier), pid_t: 0)
            runningItems.insert(finderItem, at: 0)
            dockItems.insert(finderItem, at: 0)
        }
        delegate?.didUpdate(apps: dockItems)
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
        persistentApps = []
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
                                    icon: DockRepository.getIcon(forBundleIdentifier: bundleIdentifier),
                                    pid_t: 0,
                                    launching: false)
                persistentApps.append(item)
                dockItems.append(item)
            }
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
        persistentItems = []
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
            /// Create item
            let item = DockItem(index,
                                nil,
                                name: label,
                                path: URL(string: path),
                                icon: DockRepository.getIcon(orPath: path.replacingOccurrences(of: "file://", with: "")),
                                launching: false,
                                persistentItem: true)
            persistentItems.append(item)
        }
        if !defaults[.hideTrash] && !persistentItems.contains(where: { $0.path?.absoluteString == Constants.trashPath }) {
            let trashType = ((try? FileManager.default.contentsOfDirectory(atPath: Constants.trashPath).isEmpty) ?? true) ? "TrashIcon" : "FullTrashIcon"
            let trashItem = DockItem(0, nil, name: "Trash", path: URL(string: "file://"+Constants.trashPath)!, icon: DockRepository.getIcon(orType: trashType), persistentItem: true)
            persistentItems.append(trashItem)
        }
        delegate?.didUpdate(items: persistentItems)
    }
    
    /// Load running dot
    @objc private func updateRunningState(_ notification: NSNotification?) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let s = self else { return }
            for item in s.dockItems {
                item.pid_t = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == item.bundleIdentifier })?.processIdentifier ?? 0
            }
            s.delegate?.didUpdateRunningState(for: s.dockItems)
            s.updateBouncing(for: notification)
        }
    }
    
    /// Update bouncing
    private func updateBouncing(for notification: NSNotification?) {
        if notification?.name == NSWorkspace.willLaunchApplicationNotification {
            if let app = notification?.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if let item = dockItems.first(where: { $0.bundleIdentifier == app.bundleIdentifier }), !item.isLaunching {
                    item.isLaunching = true
                    delegate?.didUpdateRunningState(for: dockItems)
                }
            }
        }else if notification?.name == NSWorkspace.didLaunchApplicationNotification ||
                 notification?.name == NSWorkspace.didActivateApplicationNotification {
            if let app = notification?.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if let item = dockItems.first(where: { $0.bundleIdentifier == app.bundleIdentifier }), item.isLaunching {
                    item.isLaunching = false
                    delegate?.didUpdateRunningState(for: dockItems)
                }
            }
        }
    }
    
    /// Load notification badges
    private func updateNotificationBadges() {
        guard shouldShowNotificationBadge else { return }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let s = self else { return }
            for item in s.dockItems {
                item.badge = PockDockHelper.sharedInstance()?.getBadgeCountForItem(withName: item.name)
            }
            s.delegate?.didUpdateBadge(for: s.dockItems)
        }
    }
    
}

extension DockRepository: FileMonitorDelegate {
    func didChange(fileMonitor: FileMonitor, paths: [String]) {
        for path in paths {
            if !isProd { NSLog("[Pock]: [\(type(of: fileMonitor))] # Changes in path: \(path)") }
        }
        self.reload(nil)
    }
}

extension DockRepository {
    /// Get icon
    public class func getIcon(forBundleIdentifier bundleIdentifier: String? = nil, orPath path: String? = nil, orType type: String? = nil) -> NSImage? {
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
    /// Launch app or open file/directory from bundle identifier
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
            let path:        String   = bundleIdentifier!
            var isDirectory: ObjCBool = true
            let url:         URL      = URL(string: path)!
            FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            if isDirectory.boolValue && openFinderInsidePock {
                dockFolderRepository?.popToRootDockFolderController()
                dockFolderRepository?.push(url)
                returnable = true
            }else {
                returnable = NSWorkspace.shared.open(url)
            }
        }else {
            /// Open Finder in Touch Bar
            if bundleIdentifier == "com.apple.finder" && openFinderInsidePock {
                dockFolderRepository?.popToRootDockFolderController()
                dockFolderRepository?.push(URL(string: NSHomeDirectory())!)
                returnable = true
            }else {
                /// Launch app
                returnable = NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleIdentifier!, options: [NSWorkspace.LaunchOptions.default], additionalEventParamDescriptor: nil, launchIdentifier: nil)
            }
        }
        /// Return status
        completion(returnable)
    }
    /// TO_IMPROVE: If app is already running, do some special things
    public func launch(item: DockItem?, completion: (Bool) -> ()) {
        guard let _item = item, let identifier = _item.bundleIdentifier else {
            launch(bundleIdentifier: item?.path?.absoluteString, completion: completion)
            return
        }
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
        guard apps.count > 0 else {
            launch(bundleIdentifier: _item.bundleIdentifier ?? _item.path?.absoluteString, completion: completion)
            return
        }
        if apps.count > 1 {
            var result = false
            for app in apps {
                result = activate(app: app)
                if result == false { break }
            }
            completion(result)
        }else {
            completion(activate(app: apps.first))
        }
    }
    
    @discardableResult
    private func activate(app: NSRunningApplication?) -> Bool {
        guard let app = app else { return false }
        // TODO: Create preference option for this
        let shouldOpenAppExpose: Bool = true
        let windowsCount = PockDockHelper.sharedInstance()?.windowsCount(forApp: app) ?? 0
        if windowsCount > 0 && shouldOpenAppExpose {
            activateExpose(app: app)
            return true
        }else {
            if !app.unhide() {
               return app.activate(options: .activateIgnoringOtherApps)
            }
            return true
        }
    }
    
    private func activateExpose(app: NSRunningApplication) {
        if !isProd { print("[Pock]: Exposé requested for: \(app.localizedName ?? "Unknown")") }
        guard let windows = PockDockHelper.sharedInstance()?.getWindowsOfApp(app.processIdentifier) as? [AppExposeItem], windows.count > 0 else {
            if !isProd { print("[Pock]: Can't load exposé items for: \(app.localizedName ?? "Unknown")") }
            return
        }
        guard windows.count > 1 else {
            if !isProd { print("[Pock]: Abort exposé. Reason: not needed for single element") }
            PockDockHelper.sharedInstance()?.activateWindow(withID: windows.first!.wid, forApp: app)
            return
        }
        if !isProd { print("[Pock]: Will open exposé for: \(app.localizedName ?? "Unknown")") }
        openExpose(with: windows, for: app)
    }
}

extension DockRepository {
    public func openExpose(with images: [AppExposeItem], for app: NSRunningApplication) {
        let controller: AppExposeController = AppExposeController.load()
        controller.set(app: app)
        controller.set(elements: images)
        AppDelegate.default.navController?.push(controller)
    }
}

extension DockRepository {
    
    /// Update notification badge refresh timer
    @objc private func setupNotificationBadgeRefreshTimer() {
        /// Get refresh rate
        let refreshRate = defaults[.notificationBadgeRefreshInterval]
        /// Invalidate last timer
        self.notificationBadgeRefreshTimer?.invalidate()
        /// Check if disabled
        guard refreshRate.rawValue >= 0 else { return }
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
