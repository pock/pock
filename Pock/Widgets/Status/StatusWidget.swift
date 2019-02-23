//
//  StatusWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class StatusWidget: PockWidget {
    
    /// Core
    private let statusElements: [StatusItem] = [
        SWifiItem()
    ]
    private var statusElementViews: [String: NSView] = [:]
    
    /// UI
    private let stackView: NSStackView = NSStackView(frame: .zero)
    
    override func customInit() {
        self.customizationLabel = "Status"
        self.loadStatusElements()
        self.set(view: stackView)
    }
    
    private func clearStackView() {
        stackView.arrangedSubviews.forEach({ subview in
            stackView.removeArrangedSubview(subview)
            stackView.removeView(subview)
        })
    }
    
    private func loadStatusElements() {
        clearStackView()
        statusElements.forEach({ item in
            if let cachedView = statusElementViews[item.title] {
                stackView.addArrangedSubview(cachedView)
            }else {
                statusElementViews[item.title] = item.view
                stackView.addArrangedSubview(item.view)
            }
        })
    }
}
