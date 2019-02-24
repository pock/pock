//
//  SClockItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class SClockItem: StatusItem {
    
    /// UI
    private let clockLabel: NSTextField!
    
    init() {
        clockLabel = NSTextField()
        clockLabel.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 44))
        clockLabel.font = NSFont.systemFont(ofSize: 13)
        clockLabel.backgroundColor = .clear
        clockLabel.isBezeled = false
        clockLabel.isEditable = false
        clockLabel.sizeToFit()
        reload()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reload), userInfo: nil, repeats: true)
    }
    
    var title: String  { return "clock" }
    
    var view: NSView { return clockLabel }
    
    func action() {
        print("[Pock]: Clock Status icon tapped!")
    }
    
    @objc func reload() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE dd MMM HH:mm"
        formatter.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en_US_POSIX")
        clockLabel.stringValue = formatter.string(from: Date())
        clockLabel.sizeToFit()
    }
    
}
