//
//  PockWidgetDocument.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import AppKit

public class PockWidgetDocument: NSDocument {
    
    private func installWidget(at path: URL) throws {
        defer {
            close()
        }
        try PockHelper.default.openProcessControllerForWidget(at: path, process: .install)
    }
    
    init(contentsOf url: URL, ofType typeName: String) throws {
        super.init()
        try installWidget(at: url)
    }
    
}
