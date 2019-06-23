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
    
    private var navController: PKTouchBarNavController? { return (NSApp.delegate as? AppDelegate)?.navController }
    
    public var shouldShowBackButton: Bool {
        return navController?.childControllers.count ?? 0 > 2
    }
    
    init(path: URL? = nil) {
        guard path != nil else { return }
        let controller: DockFolderController = DockFolderController.load()
        controller.set(dockFolderRepository: self)
        controller.set(folderUrl: path!)
        navController?.push(controller)
    }
    
    func getItems(in path: URL, _ completion: (([DockFolderItem]) -> Void)?) {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey,
                                                      .isApplicationKey,
                                                      .effectiveIconKey,
                                                      .nameKey,
                                                      .localizedTypeDescriptionKey]
        DispatchQueue.global(qos: .background).async {
            var returnable: [DockFolderItem] = []
            let enumerator = FileManager.default.enumerator(at: path,
                                                            includingPropertiesForKeys: resourceKeys,
                                                            options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants, .skipsHiddenFiles],
                                                            errorHandler: nil)
            while let elementUrl = enumerator?.nextObject() as? URL {
                guard let itemData = try? elementUrl.resourceValues(forKeys: Set(resourceKeys)).allValues else {
                    continue
                }
                let icon          = DockFolderRepository.icon(for: elementUrl) ?? itemData[.effectiveIconKey] as? NSImage
                let name          = itemData[.nameKey]                     as? String
                let detail        = itemData[.localizedTypeDescriptionKey] as? String
                let isDirectory   = itemData[.isDirectoryKey]              as? Bool
                let isApplication = itemData[.isApplicationKey]            as? Bool
                let item = DockFolderItem(0, name: name, detail: detail, path: elementUrl, icon: icon, isDirectory: isDirectory, isApplication: isApplication)
                returnable.append(item)
            }
            returnable.sort(by: { $0.name ?? "" < $1.name ?? "" })
            DispatchQueue.main.async {
                completion?(returnable)
            }
        }
    }
    
    func open(item: DockFolderItem, completion: ((Bool) -> Void)? = nil) {
        var completed: Bool     = false
        var shouldDismiss: Bool = true
        if item.isApplication {
            let app = try? NSWorkspace.shared.launchApplication(at: item.path!, options: [NSWorkspace.LaunchOptions.default], configuration: [:])
            completed = app != nil
            
        }else if item.isDirectory {
            push(item.path!)
            completed     = true
            shouldDismiss = false
            
        }else {
            completed = NSWorkspace.shared.open(item.path!)
        }
        if shouldDismiss {
            popToRootDockFolderController()
        }
        completion?(completed)
    }
    
}

extension DockFolderRepository {
    public func push(_ path: URL) {
        let controller: DockFolderController = DockFolderController.load()
        controller.set(dockFolderRepository: self)
        controller.set(folderUrl: path)
        navController?.push(controller)
    }
    public func popDockFolderController() {
        navController?.popLastController()
    }
    public func popToRootDockFolderController() {
        navController?.popToRootController()
    }
}

extension DockFolderRepository {
    class func icon(for url: URL) -> NSImage? {
        var options: CFDictionary? = [kQLThumbnailOptionIconModeKey: false] as CFDictionary
        var ref = QLThumbnailCreate(kCFAllocatorDefault, url as NSURL, CGSize(width: 30, height: 30), options)
        var thumbnail = ref?.takeRetainedValue()
        var cgImageRef = QLThumbnailCopyImage(thumbnail)
        let cgImage = cgImageRef?.takeRetainedValue()
        options    = nil
        ref        = nil
        thumbnail  = nil
        cgImageRef = nil
        guard cgImage != nil else { return nil }
        return NSImage(cgImage: cgImage!, size: CGSize(width: cgImage!.width, height: cgImage!.height))
    }
}
