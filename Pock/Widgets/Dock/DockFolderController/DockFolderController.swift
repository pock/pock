//
//  DockFolderController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class DockFolderController: PockTouchBarController {
    
    /// UI
    @IBOutlet private weak var folderName: NSTextField!
    
    /// Core
    var folderUrl: URL!
    
    override func present() {
        guard folderUrl != nil else { return }
        super.present()
        self.folderName.stringValue = folderUrl?.lastPathComponent ?? "??"
    }
    
    @IBAction func willDismiss(_ button: NSButton?) {
        self.dismiss()
    }
    
    @IBAction func willOpen(_ button: NSButton?) {
        NSWorkspace.shared.open(folderUrl)
        self.dismiss()
    }
    
}
