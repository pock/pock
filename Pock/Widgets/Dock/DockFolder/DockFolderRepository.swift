//
//  DockFolderRepository.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class DockFolderRepository {
    
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
            let icon    = itemData[.effectiveIconKey]            as? NSImage
            let name    = itemData[.nameKey]                     as? String
            let detail  = itemData[.localizedTypeDescriptionKey] as? String
            let item    = DockFolderItem(0, name: name, detail: detail, path: elementUrl, icon: icon)
            returnable.append(item)
        }
        return returnable.sorted(by: { $0.name ?? "" < $1.name ?? "" })
    }
    
}
