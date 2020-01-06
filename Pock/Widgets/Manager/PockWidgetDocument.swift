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
        do {
            try WidgetsDispatcher.default.installWidget(at: path)
            AppDelegate.default.openWidgetsManager()
            NotificationCenter.default.post(name: .didInstallWidget, object: nil)
        } catch {
            NSLog("[PockWidgetDocument]: Can't install widget. Reason: \(error.localizedDescription)")
        }
    }
    
    init(contentsOf url: URL, ofType typeName: String) throws {
        super.init()
        try installWidget(at: url)
    }
    
}
