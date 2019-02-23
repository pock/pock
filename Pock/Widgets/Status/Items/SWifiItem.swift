//
//  SWifiItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class SWifiItem: StatusItem {
    
    override var title: String  { return "wifi" }
    
    override var view: NSView { return NSImageView(image: NSImage(named: .touchBarVolumeDownTemplate)!) }
    
    override func action() {
        print("[Pock]: WiFi Status icon tapped!")
    }
    
}
