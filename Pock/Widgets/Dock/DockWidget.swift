//
//  DockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class DockWidget: PockWidget {
    
    /// Core
    private var dockRepository:                DockRepository!
    private var notificationBadgeRefreshTimer: Timer!
    
    /// UI
    private var dockScrubber: NSScrubber = NSScrubber(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
    
    /// Data
    private var itemViews: [String: DockItemView] = [:]
    private var items:     [DockItem] = []
    
    /// Custom init
    override func customInit() {
        self.customizationLabel = "Dock"
        self.configureDockScrubber()
        self.set(view: dockScrubber)
        self.dockRepository = DockRepository(delegate: self)
        self.dockRepository.reload(nil)
    }
    
    /// Configure dock scrubber
    private func configureDockScrubber() {
        let layout = NSScrubberFlowLayout()
        layout.itemSize = Constants.dockItemSize
        dockScrubber.dataSource = self
        dockScrubber.delegate = self
        dockScrubber.showsAdditionalContentIndicators = true
        dockScrubber.mode = .free
        dockScrubber.isContinuous = false
        dockScrubber.itemAlignment = .none
        dockScrubber.scrubberLayout = layout
    }
    
}

extension DockWidget: DockDelegate {
    func didUpdateRunningApps(apps: [DockItem]) {
        self.items = apps
        self.dockScrubber.reloadData()
    }
}

extension DockWidget: NSScrubberDataSource {
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return items.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let item = items[index]
        var view = itemViews[item.bundleIdentifier]
        if view == nil {
            view = DockItemView(frame: .zero)
            view?.dockItem = item
            itemViews[item.bundleIdentifier] = view
        }else {
            view?.reload()
        }
        view!.frame.size = Constants.dockItemSize
        return view!
    }
}

extension DockWidget: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        let item = items[selectedIndex]
        print(item.bundleIdentifier)
        scrubber.selectedIndex = -1
    }
}
