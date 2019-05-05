//
//  SClockItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class SClockItem: StatusItem {
    
    /// Core
    private weak var refreshTimer: Timer?
    
    /// UI
    private var clockLabel: NSTextField!
    
    init() {
        clockLabel = NSTextField()
        clockLabel.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 44))
        clockLabel.font = NSFont.systemFont(ofSize: 13)
        clockLabel.backgroundColor = .clear
        clockLabel.isBezeled = false
        clockLabel.isEditable = false
        clockLabel.sizeToFit()
        reload()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.reload()
        })
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
        clockLabel = nil
    }
    
    var enabled: Bool{ return defaults[.shouldShowDateItem] }
    
    var title: String  { return "clock" }
    
    var view: NSView { return clockLabel }
    
    func action() {
        if !isProd { print("[Pock]: Clock Status icon tapped!") }
    }
    
    func reload() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE dd MMM HH:mm"
        formatter.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en_US_POSIX")
        clockLabel.stringValue = formatter.string(from: Date())
        clockLabel.sizeToFit()
    }
    
}
