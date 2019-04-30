//
//  FileEvent.swift
//  Witness
//
//  Created by Niels de Hoog on 24/09/15.
//  Copyright © 2015 Invisible Pixel. All rights reserved.
//

import Foundation

public struct FileEvent {
    public let path: String
    public let flags: FileEventFlags
}

public struct FileEventFlags: OptionSet {
    public let rawValue: FSEventStreamEventFlags
    public init(rawValue: FSEventStreamEventFlags) { self.rawValue = rawValue }
    init(_ value: Int) { self.rawValue = FSEventStreamEventFlags(value) }
    
    public static let None = FileEventFlags(kFSEventStreamEventFlagNone)
    
    public static let MustScanSubDirs = FileEventFlags(kFSEventStreamEventFlagMustScanSubDirs)
    
    public static let UserDropped = FileEventFlags(kFSEventStreamEventFlagUserDropped)
    public static let KernelDropped = FileEventFlags(kFSEventStreamEventFlagKernelDropped)
    
    public static let EventIdsWrapped = FileEventFlags(kFSEventStreamEventFlagEventIdsWrapped)
    
    public static let HistoryDone = FileEventFlags(kFSEventStreamEventFlagHistoryDone)
    
    public static let RootChanged = FileEventFlags(kFSEventStreamEventFlagRootChanged)
    
    public static let Mount = FileEventFlags(kFSEventStreamEventFlagMount)
    public static let Unmount = FileEventFlags(kFSEventStreamEventFlagUnmount)
    
    public static let ItemCreated = FileEventFlags(kFSEventStreamEventFlagItemCreated)
    public static let ItemRemoved = FileEventFlags(kFSEventStreamEventFlagItemRemoved)
    public static let ItemInodeMetaMod = FileEventFlags(kFSEventStreamEventFlagItemInodeMetaMod)
    public static let ItemRenamed = FileEventFlags(kFSEventStreamEventFlagItemRenamed)
    public static let ItemModified = FileEventFlags(kFSEventStreamEventFlagItemModified)
    public static let ItemFinderInfoMod = FileEventFlags(kFSEventStreamEventFlagItemFinderInfoMod)
    public static let ItemChangeOwner = FileEventFlags(kFSEventStreamEventFlagItemChangeOwner)
    public static let ItemXattrMod = FileEventFlags(kFSEventStreamEventFlagItemXattrMod)
    public static let ItemIsFile = FileEventFlags(kFSEventStreamEventFlagItemIsFile)
    public static let ItemIsDir = FileEventFlags(kFSEventStreamEventFlagItemIsDir)
    public static let ItemIsSymlink = FileEventFlags(kFSEventStreamEventFlagItemIsSymlink)
    public static let ItemIsHardLink = FileEventFlags(kFSEventStreamEventFlagItemIsHardlink)
    public static let ItemIsLastHardLink = FileEventFlags(kFSEventStreamEventFlagItemIsLastHardlink)
    
    public static let OwnEvent = FileEventFlags(kFSEventStreamEventFlagOwnEvent)
}

extension FileEventFlags: CustomStringConvertible {
    public var description: String {
        var strings = [String]()
        
        if self == .None {
            strings.append("None")
        }
        if (self.contains(.MustScanSubDirs)) {
            strings.append("Must Scan Subdirectories")
        }
        if (self.contains(.UserDropped)) {
            strings.append("User Dropped")
        }
        if (self.contains(.KernelDropped)) {
            strings.append("Kernel Dropped")
        }
        if (self.contains(.EventIdsWrapped)) {
            strings.append("Event IDs wrapped")
        }
        if (self.contains(.HistoryDone)) {
            strings.append("History Done")
        }
        if (self.contains(.RootChanged)) {
            strings.append("Root Changed")
        }
        if (self.contains(.Mount)) {
            strings.append("Mount")
        }
        if (self.contains(.Unmount)) {
            strings.append("Unmount")
        }
        if (self.contains(.ItemCreated)) {
            strings.append("Item created")
        }
        if (self.contains(.ItemRemoved)) {
            strings.append("Item Removed")
        }
        if (self.contains(.ItemInodeMetaMod)) {
            strings.append("Item Inode Meta Modification")
        }
        if (self.contains(.ItemRenamed)) {
            strings.append("Item Renamed")
        }
        if (self.contains(.ItemModified)) {
            strings.append("Item Modified")
        }
        if (self.contains(.ItemFinderInfoMod)) {
            strings.append("Item Finder Info Modification")
        }
        if (self.contains(.ItemChangeOwner)) {
            strings.append("Item Change Owner")
        }
        if (self.contains(.ItemXattrMod)) {
            strings.append("Item Xattr Modification")
        }
        if (self.contains(.ItemIsFile)) {
            strings.append("Item Is File")
        }
        if (self.contains(.ItemIsDir)) {
            strings.append("Item Is Directory")
        }
        if (self.contains(.ItemIsSymlink)) {
            strings.append("Item Is Symbolic Link")
        }
        if (self.contains(.ItemIsHardLink)) {
            strings.append("Item Is Hard Link")
        }
        if (self.contains(.ItemIsLastHardLink)) {
            strings.append("Item Is Last Hard Link")
        }
        if (self.contains(.OwnEvent)) {
            strings.append("Own event")
        }
        
        return strings.joined(separator: ",")
    }
}
