//
//  DockFolderRepository.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Quartz

class DockFolderRepository {
    
    /// Public
    public let rootDockFolderController: DockFolderController
    
    init(rootDockFolderController: DockFolderController) {
        self.rootDockFolderController = rootDockFolderController
        self.rootDockFolderController.set(dockFolderRepository: self)
        self.rootDockFolderController.present()
    }
    
    private let resourceKeys: [URLResourceKey] = [.isDirectoryKey,
                                                 .isApplicationKey,
                                                 .effectiveIconKey,
                                                 .nameKey,
                                                 .localizedTypeDescriptionKey]
    
    func getItems(in path: URL) -> [DockFolderItem] {
        var returnable: [DockFolderItem] = []
        let enumerator = FileManager.default.enumerator(at: path,
                                                        includingPropertiesForKeys: resourceKeys,
                                                        options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants, .skipsHiddenFiles],
                                                        errorHandler: nil)
        while let elementUrl = enumerator?.nextObject() as? URL {
            guard let itemData = try? elementUrl.resourceValues(forKeys: Set(resourceKeys)).allValues else {
                continue
            }
            let icon          = self.icon(for: elementUrl) ?? itemData[.effectiveIconKey] as? NSImage
            let name          = itemData[.nameKey]                     as? String
            let detail        = itemData[.localizedTypeDescriptionKey] as? String
            let isDirectory   = itemData[.isDirectoryKey]              as? Bool
            let isApplication = itemData[.isApplicationKey]            as? Bool
            let item = DockFolderItem(0, name: name, detail: detail, path: elementUrl, icon: icon, isDirectory: isDirectory, isApplication: isApplication)
            returnable.append(item)
        }
        return returnable.sorted(by: { $0.name ?? "" < $1.name ?? "" })
    }
    
    func open(item: DockFolderItem, completion: ((Bool) -> Void)? = nil) {
        var completed: Bool     = false
        var shouldDismiss: Bool = true
        if !(item.path?.lastPathComponent.contains(".app") ?? false) && item.isDirectory {
            let controller: DockFolderController = DockFolderController.load()
            controller.set(folderUrl: item.path!)
            rootDockFolderController.push(controller)
            shouldDismiss = false
            
        }else if item.isApplication {
            let app = try? NSWorkspace.shared.launchApplication(at: item.path!, options: [NSWorkspace.LaunchOptions.default], configuration: [:])
            completed = app != nil
            
        }else {
            completed = NSWorkspace.shared.open(item.path!)
        }
        if shouldDismiss {
            rootDockFolderController.popToRootDockFolderController(shouldDismiss: true)
        }
        completion?(completed)
    }
    
}

extension DockFolderRepository {
    private func icon(for url: URL) -> NSImage? {
        let options = [kQLThumbnailOptionIconModeKey: false]
        let ref = QLThumbnailCreate(kCFAllocatorDefault, url as NSURL, CGSize(width: 30, height: 30), options as CFDictionary)
        let thumbnail = ref?.takeRetainedValue()
        let cgImageRef = QLThumbnailCopyImage(thumbnail)
        guard let cgImage = cgImageRef?.takeRetainedValue() else { return nil }
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
    }
}
