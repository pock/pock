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
        dockScrubber.register(DockItemView.self, forItemIdentifier: Constants.kDockItemView)
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
            for (index, old_app) in old_apps.enumerated() {
                if !new_apps.contains(old_app) {
                    scrubber.removeItems(at: IndexSet(integer: index))
                    count -= 1
                }
            }
            for new_app in new_apps {
                if !old_apps.contains(new_app) {
                    scrubber.insertItems(at: IndexSet(integer: count))
                    count += 1
                }
            }
            self?.items = new_apps
        }
    }
    func didUpdateBadge(for apps: [DockItem]) {
        for (index, item) in items.enumerated() {
            if let view = dockScrubber.itemViewForItem(at: index) as? DockItemView {
                view.set(hasBadge: item.hasBadge)
            }
        }
//        for (key, view) in itemViews {
//            if let item = apps.first(where: { $0.bundleIdentifier == key }) {
//                view.set(hasBadge: item.hasBadge)
//            }else {
//                view.set(hasBadge: false)
//            }
//        }
    }
    func didUpdateRunningState(for apps: [DockItem]) {
        for (index, item) in items.enumerated() {
            if let view = dockScrubber.itemViewForItem(at: index) as? DockItemView {
                view.set(isRunning: item.isRunning)
                view.set(isFrontmost: item.isFrontmost)
            }
        }
//        for (key, view) in itemViews {
//            if let item = apps.first(where: { $0.bundleIdentifier == key }) {
//                view.set(isRunning: item.isRunning)
//            }else {
//                view.set(isRunning: false)
//            }
//        }
    }
}

extension DockWidget: NSScrubberDataSource {
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return items.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let item = items[index]
        let view = scrubber.makeItem(withIdentifier: Constants.kDockItemView, owner: self) as! DockItemView
        view.set(icon:         item.icon)
        view.set(hasBadge:     item.hasBadge)
        view.set(isRunning:    item.isRunning)
        view.set(isFrontmost:  item.isFrontmost)
        if let key = item.bundleIdentifier ?? item.path?.absoluteString {
            itemViews[key] = view
        }
        return view
    }
}

extension DockWidget: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        let item = items[selectedIndex]
        dockRepository.launch(bundleIdentifier: item.bundleIdentifier, completion: { success in
            NSLog("[Pock]: Did open: \(item.bundleIdentifier ?? item.path?.absoluteString ?? "Unknown") [success: \(success)]")
        })
        scrubber.selectedIndex = -1
    }
}
