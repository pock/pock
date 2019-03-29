//
//  PockUtilities.swift
//  Pock
//
//  Created by Pierluigi Galdi on 08/09/17.
//  Copyright © 2017 Pierluigi Galdi. All rights reserved.
//

import Foundation
import AppKit
import SnapKit

public class PockUtilities {
    
    /// Singleton
    public static let `default`: PockUtilities = PockUtilities()
    private init() {
        self.lock = NSRecursiveLock()
    }
    
    /// Core
    private let lock: NSRecursiveLock!
    
    /// Known identifiers
    private let kFinderIdentifier: String = "com.apple.finder"
    
    /// Persistent apps identifiers
    private var persistentAppsIdentifiers: [String] = []
    
    /// Known paths
    public let dockPlist = NSHomeDirectory().appending("/Library/Preferences/com.apple.dock.plist")
    public let trashPath = NSHomeDirectory().appending("/.Trash")
    
    /// Runnings apps identifiers
    public var runningAppsIdentifiers: [String?] {
        return NSWorkspace.shared.runningApplications.map({ $0.bundleIdentifier })
    }
    
    /// Get top most application bundle identifier
    public var frontmostApplicationIdentifier: String? {
        get {
            guard let frontmostId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return nil }
            return frontmostId
        }
    }
    
    /// Returns bundle identifier for the Dock's persistent apps.
    public func getDockPersistentAppsList() -> [PockItem] {
        
        self.lock.lock(); defer { self.lock.unlock() }
        
        /// Remove all from persistentIdentifiers array
        PockUtilities.default.persistentAppsIdentifiers = []
        
        /// Declare returnable array.
        var returnable: [PockItem] = []
        
        /// Read data from Dock's preferences file.
        guard let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.dock") else {
            // TODO: Handle error.
            print("Can't read Dock preferences file")
            return returnable
        }
        
        /// Read persistent apps array.
        guard let persistentApps = dict["persistent-apps"] as? [[String: Any]] else {
            // TODO: Handle error.
            print("Can't get persistent apps")
            return returnable
        }
        
        /// Iterate on persistent apps array.
        for (ind, appItem) in persistentApps.enumerated() {
            
            /// Get item tile data.
            guard let tileData = appItem["tile-data"] as? [String: Any] else {
                // TODO: Handle error.
                print("Can't get app tile-data")
                continue
            }
            
            /// Get app's label.
            guard let label = tileData["file-label"] as? String else {
                // TODO: Handle error.
                print("Can't get app label")
                continue
            }
            
            /// Get app's bundle identifier.
            guard let bundleIdentifier = tileData["bundle-identifier"] as? String else {
                // TODO: Handle error.
                print("Can't read bundle identifier")
                continue
            }
            
            /// Add to static identifiers array
            PockUtilities.default.persistentAppsIdentifiers.append(bundleIdentifier)
            
            /// Add bundle identifier to returnable array.
            let dockItem = PockItem(label: label, bundleIdentifier: bundleIdentifier, icon: PockUtilities.default.getIcon(forBundleIdentifier: bundleIdentifier))
            returnable.insert(dockItem, at: ind)
            
        }
        
        /// Insert Finder as first
        let finderItem = PockItem(label: "Finder", bundleIdentifier: kFinderIdentifier, icon: PockUtilities.default.getIcon(forBundleIdentifier: kFinderIdentifier))
        returnable.insert(finderItem, at: 0)
        
        /// Add Finder identifier to persistentAppsIdentifiers array. This way, "getMissingRunningApps()" will not re-add it to final items array
        PockUtilities.default.persistentAppsIdentifiers.insert(kFinderIdentifier, at: 0)
        
        /// Return returnable array.
        return returnable
    
    }
    
    /// Returns remaining running apps that ar not present in persistent-apps list in com.apple.dock.plist
    public func getMissingRunningApps() -> [PockItem] {
        
        self.lock.lock(); defer { self.lock.unlock() }
        
        /// Declare returnable
        var returnable: [PockItem] = []
        
        /// Iterate on running appps from shared NSWorkspace
        for app in NSWorkspace.shared.runningApplications {
            
            /// Check for policy
            guard app.activationPolicy == NSApplication.ActivationPolicy.regular else { continue }
            
            /// Get app identifier
            guard let id = app.bundleIdentifier else { continue }
            
            /// Create dock item, if already not present
            guard PockUtilities.default.persistentAppsIdentifiers.contains(id) == false else { continue }
            guard let label = app.localizedName else { continue }
            let dockItem = PockItem(label: label, bundleIdentifier: id, icon: PockUtilities.default.getIcon(forBundleIdentifier: id))
            returnable.append(dockItem)
        
        }
        
        /// Return DockItem's array
        return returnable
    
    }
    
    /// Returns Label and path for the Dock's persistent others.
    public func getDockPersistentOthersList() -> [PockItem] {
        
        self.lock.lock(); defer { self.lock.unlock() }
        
        /// Declare returnable array.
        var returnable: [PockItem] = []
        
        /// Read data from Dock's preferences file.
        guard let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.dock") else {
            // TODO: Handle error.
            print("Can't read Dock preferences file")
            return returnable
        }
        
        /// Read persistent others array.
        guard let persistentApps = dict["persistent-others"] as? [[String: Any]] else {
            // TODO: Handle error.
            print("Can't get persistent apps")
            return returnable
        }
        
        /// Iterate on persistent others array.
        for (ind, otherItem) in persistentApps.enumerated() {
            
            /// Get item tile data.
            guard let tileData = otherItem["tile-data"] as? [String: Any] else {
                // TODO: Handle error.
                print("Can't get app tile-data")
                continue
            }
            
            /// Get other's label.
            guard let label = tileData["file-label"] as? String else {
                // TODO: Handle error.
                print("Can't read label")
                continue
            }
            
            /// Get other's file data dict.
            guard let fileData = tileData["file-data"] as? [String: Any] else {
                // TODO: Handle error.
                print("Can't read file data")
                continue
            }
            
            /// Get other's file path
            guard let path = fileData["_CFURLString"] as? String else {
                // TODO: Handle error.
                print("Can't read file path")
                continue
            }
            
            /// Get other's file type.
            let tileType = otherItem["tile-type"] as? String
            
            /// Add key-value to returnable.
            let dockItem = PockItem(label: label, bundleIdentifier: path, icon: PockUtilities.default.getIcon(forBundleIdentifier: nil, orType: tileType))
            returnable.insert(dockItem, at: ind)
            
        }
        
        /// Add trash icon
        let isTrashEmpty = (try? FileManager.default.contentsOfDirectory(atPath: trashPath).isEmpty) ?? true
        let trashItem    = PockItem(label: "Trash", bundleIdentifier: "file://".appending(trashPath), icon: PockUtilities.default.getIcon(orType: isTrashEmpty ? "TrashIcon" : "FullTrashIcon"))
        returnable.append(trashItem)
        
        /// Return returnable array.
        return returnable
        
    }
    
    /// Get icon.
    public func getIcon(forBundleIdentifier bundleIdentifier: String? = nil, orPath path: String? = nil, orType type: String? = nil) -> NSImage {
    
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
    
    /// Launch app from it's bundle identifier
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
    
    /// Get NSRunningApplication from NSNotification object
    public func getRunningApplication(from notification: NSNotification?) -> NSRunningApplication? {
        if let runningApp = notification?.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            return runningApp
        }
        return nil
    }
    
}
