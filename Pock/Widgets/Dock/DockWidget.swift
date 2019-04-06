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
    private var dockRepository: DockRepository!
    
    /// UI
    private var dockScrubber: NSScrubber = NSScrubber(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
    
    /// Data
    private var itemViews: [String: DockItemView] = [:]
    private var items:     [DockItem]             = [ ]
    
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
        layout.itemSpacing = 8
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
    func didUpdate(apps: [DockItem]) {
        dockScrubber.performSequentialBatchUpdates { [weak self] in
            guard let scrubber = self?.dockScrubber, let items = self?.items else { return }
            var count = scrubber.numberOfItems
            let old_apps = items.map({ $0 })
            let new_apps = apps.map({ $0 })
            self?.items = new_apps
            for (index, old_app) in old_apps.enumerated() {
                if !new_apps.contains(where: { $0.bundleIdentifier == old_app.bundleIdentifier }) {
                    scrubber.removeItems(at: IndexSet(integer: index))
                    count -= 1
                }
            }
            for (index,new_app) in new_apps.enumerated() {
                if old_apps.contains(where: { $0.bundleIdentifier == new_app.bundleIdentifier }) {
                    scrubber.reloadItems(at: IndexSet(integer: index))
                }else {
                    scrubber.insertItems(at: IndexSet(integer: count))
                    count += 1
                }
            }
            
        }
    }
    func didUpdateBadge(for apps: [DockItem]) {
        for (key, view) in itemViews {
            if let item = apps.first(where: { $0.bundleIdentifier == key }) {
                view.set(hasBadge: item.hasBadge)
            }else {
                view.set(hasBadge: false)
            }
        }
    }
    func didUpdateRunningState(for apps: [DockItem]) {
        for (key, view) in itemViews {
            if let item = apps.first(where: { $0.bundleIdentifier == key }) {
                view.set(isRunning: item.isRunning)
            }else {
                view.set(isRunning: false)
            }
        }
    }
}

extension DockWidget: NSScrubberDataSource {
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return items.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let item = items[index]
        var view = itemViews[item.bundleIdentifier]
        if view == nil { view = DockItemView(frame: .zero); itemViews[item.bundleIdentifier] = view }
        view!.frame.size = Constants.dockItemSize
        view!.set(hasBadge:     item.hasBadge)
        view!.set(icon:         item.icon)
        view!.set(isRunning:    item.isRunning)
        view!.set(isFrontmost:  item.isFrontmost)
        return view!
    }
}

extension DockWidget: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        let item = items[selectedIndex]
        dockRepository.launch(bundleIdentifier: item.bundleIdentifier, completion: { success in
            NSLog("[Pock]: Did open: \(item.bundleIdentifier) [success: \(success)]")
        })
        scrubber.selectedIndex = -1
    }
}
