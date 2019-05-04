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
        SWifiItem(),
        SPowerItem(),
        SClockItem()
    ]
    private var statusElementViews: [String: NSView] = [:]
    
    /// UI
    private var stackView: NSStackView!
    
    override func customInit() {
        self.customizationLabel = "Status"
        self.initStackView()
        self.loadStatusElements()
        self.set(view: stackView)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        NSWorkspace.shared.notificationCenter.addObserver(forName: .shouldReloadStatusWidget, object: nil, queue: .main, using: { [weak self] _ in
            self?.loadStatusElements()
        })
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    private func initStackView() {
        stackView = NSStackView(frame: .zero)
        stackView.orientation  = .horizontal
        stackView.alignment    = .centerY
        stackView.distribution = .fillProportionally
        stackView.spacing      = 8
    }
    
    private func clearStackView() {
        stackView.arrangedSubviews.forEach({ subview in
            stackView.removeView(subview)
        })
    }
    
    private func loadStatusElements() {
        clearStackView()
        statusElements.filter({ $0.enabled }).forEach({ item in
            if let cachedView = statusElementViews[item.title] {
                item.reload()
                stackView.addArrangedSubview(cachedView)
            }else {
                statusElementViews[item.title] = item.view
                item.reload()
                stackView.addArrangedSubview(item.view)
            }
        })
    }
}
