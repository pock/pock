//
//  Pock.swift
//  Pock
//
//  Created by Pierluigi Galdi on 08/09/17.
//  Copyright © 2017 Pierluigi Galdi. All rights reserved.
//

import Foundation
import AppKit
import SnapKit

public class PockUtilities {
    
    /// Persistent apps identifiers
    private static var persistentAppsIdentifiers: [String] = []
    
    /// Runnings apps identifiers
    public static var runningAppsIdentifiers: [String] = []
    
    /// Get top most application bundle identifier
    public static var frontmostApplicationIdentifier: String? {
        get {
            guard let frontmostId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return nil }
            return frontmostId
        }
    }
    
    /// Returns bundle identifier for the Dock's persistent apps.
    public class func getDockPersistentAppsList() -> [PockItem] {
        
        /// Remove all from persistentIdentifiers array
        PockUtilities.persistentAppsIdentifiers = []
        
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
            PockUtilities.persistentAppsIdentifiers.append(bundleIdentifier)
            
            /// Add bundle identifier to returnable array.
            let dockItem = PockItem(label: label, bundleIdentifier: bundleIdentifier, icon: PockUtilities.getIcon(forBundleIdentifier: bundleIdentifier))
            returnable.insert(dockItem, at: ind)
            
        }
        
        /// Insert Finder as first
        let finderItem = PockItem(label: "Finder", bundleIdentifier: kFinderIdentifier, icon: PockUtilities.getIcon(forBundleIdentifier: kFinderIdentifier))
        returnable.insert(finderItem, at: 0)
        
        /// Add Finder identifier to persistentAppsIdentifiers array. This way, "getMissingRunningApps()" will not re-add it to final items array
        PockUtilities.persistentAppsIdentifiers.insert(kFinderIdentifier, at: 0)
        
        /// Return returnable array.
        return returnable
    
    }
    
    /// Returns remaining running apps that ar not present in persistent-apps list in com.apple.dock.plist
    public class func getMissingRunningApps() -> [PockItem] {
    
        /// Remove all from running apps identifiers array
        PockUtilities.runningAppsIdentifiers = []
        
        /// Declare returnable
        var returnable: [PockItem] = []
        
        /// Iterate on running appps from shared NSWorkspace
        for app in NSWorkspace.shared.runningApplications {
            
            /// Check for policy
            guard app.activationPolicy == NSApplication.ActivationPolicy.regular else { continue }
            
            /// Get app identifier
            guard let id = app.bundleIdentifier else { continue }
            
            /// Add to static identifiers array
            PockUtilities.runningAppsIdentifiers.append(id)
            
            /// Create dock item, if already not present
            guard PockUtilities.persistentAppsIdentifiers.contains(id) == false else { continue }
            guard let label = app.localizedName else { continue }
            let dockItem = PockItem(label: label, bundleIdentifier: id, icon: PockUtilities.getIcon(forBundleIdentifier: id))
            returnable.append(dockItem)
        
        }
        
        /// Return DockItem's array
        return returnable
    
    }
    
    /// Returns Label and path for the Dock's persistent others.
    public class func getDockPersistentOthersList() -> [PockItem] {
        
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
            let dockItem = PockItem(label: label, bundleIdentifier: path, icon: PockUtilities.getIcon(forBundleIdentifier: nil, orType: tileType))
            returnable.insert(dockItem, at: ind)
            
        }
        
        /// Add trash icon
        let trashPath = "file://".appending(NSHomeDirectory().appending("/.Trash"))
        let trashItem = PockItem(label: "Trash", bundleIdentifier: trashPath, icon: PockUtilities.getIcon(orType: "trash-icon"))
        returnable.append(trashItem)
        
        /// Return returnable array.
        return returnable
        
    }
    
    /// Get icon.
    public class func getIcon(forBundleIdentifier bundleIdentifier: String? = nil, orPath path: String? = nil, orType type: String? = nil) -> NSImage {
    
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
            
            }else if type == "trash-icon" {
            
                genericIconPath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/TrashIcon.icns"
            
            }
            
        }
        
        /// Load image
        let genericIcon = NSImage(contentsOfFile: genericIconPath)
        
        /// Return icon
        return genericIcon ?? NSImage(size: .zero)
    
    }
    
    /// Launch app from it's bundle identifier
    public class func launch(bundleIdentifier: String?, completion: (Bool) -> ()) {
        
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
