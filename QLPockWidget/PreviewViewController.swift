//
//  PreviewViewController.swift
//  QLPockWidget
//
//  Created by Pierluigi Galdi on 06/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Quartz

fileprivate let preferredSize: NSSize = NSSize(width: 480, height: 190)

class PreviewViewController: NSViewController, QLPreviewingController {
    
    // MARK: UI Elements
    @IBOutlet private weak var iconView:     NSImageView!
    @IBOutlet private weak var nameLabel:    NSTextField!
    @IBOutlet private weak var versionLabel: NSTextField!
    @IBOutlet private weak var authorLabel:  NSTextField!
    @IBOutlet private weak var bundleLabel:  NSTextField!
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }
    
    override var preferredMinimumSize: NSSize {
        return preferredSize
    }
    
    override var preferredMaximumSize: NSSize {
        return preferredSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = preferredSize
    }
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        do {
            /// Load widget info
            let widget = try WidgetInfo(path: url)
            
            /// Set icon
            iconView.image = NSImage(named: "WidgetsManagerList")
            
            /// Set data
            nameLabel.stringValue    = widget.name
            versionLabel.stringValue = widget.version
            authorLabel.stringValue  = widget.author
            bundleLabel.stringValue  = widget.id
            
            /// Call handler
            handler(nil)
        
        } catch {
            handler(error)
        }
    }
}
