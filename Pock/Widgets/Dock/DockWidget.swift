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
    private var stackView:    NSStackView!
    private var dockScrubber: NSScrubber = NSScrubber(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
    private var persistentScrubber: NSScrubber = NSScrubber(frame: NSRect(x: 0, y: 0, width: 50, height: 30))
    
    /// Data
    private var dockItems:       [DockItem] = []
    private var persistentItems: [DockItem] { return dockRepository.persistentItems }
    
    /// Custom init
    override func customInit() {
        self.customizationLabel = "Dock"
        self.configureStackView()
        self.configureDockScrubber()
        self.configureSeparator()
        self.configurePersistentScrubber()
        self.set(view: stackView)
        self.dockRepository = DockRepository(delegate: self)
        self.dockRepository.reload(nil)
    }
    
    /// Configure stack view
    private func configureStackView() {
        stackView = NSStackView(frame: .zero)
        stackView.alignment = .centerY
        stackView.orientation = .horizontal
        stackView.distribution = .fill
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
        stackView.addArrangedSubview(dockScrubber)
    }
    
    /// Configure separator
    private func configureSeparator() {
        let separator: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 20))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.darkGray.cgColor
        separator.snp.makeConstraints({ m in
            m.width.equalTo(1)
            m.height.equalTo(20)
        })
        stackView.addArrangedSubview(separator)
    }
    
    /// Configure persistent scrubber
    private func configurePersistentScrubber() {
        let layout = NSScrubberFlowLayout()
        layout.itemSize = Constants.dockItemSize
        layout.itemSpacing = 8
        persistentScrubber.dataSource = self
        persistentScrubber.delegate = self
        persistentScrubber.register(DockItemView.self, forItemIdentifier: Constants.kDockItemView)
        persistentScrubber.showsAdditionalContentIndicators = true
        persistentScrubber.mode = .free
        persistentScrubber.isContinuous = false
        persistentScrubber.itemAlignment = .none
        persistentScrubber.scrubberLayout = layout
        persistentScrubber.snp.makeConstraints({ m in
            m.width.equalTo(136)
        })
        stackView.addArrangedSubview(persistentScrubber)
    }
    
}

extension DockWidget: DockDelegate {
    func didUpdate(apps: [DockItem]) {
        dockScrubber.performSequentialBatchUpdates { [weak self] in
            guard let scrubber = self?.dockScrubber, let items = self?.dockItems else { return }
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
                    if old_apps.count > 0 {
                        scrubber.scrollItem(at: count - 1, to: .leading)
                    }
                    count += 1
                }
            }
            self?.dockItems = new_apps
        }
    }
    func didUpdateBadge(for apps: [DockItem]) {
        for (index, item) in dockItems.enumerated() {
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
        for (index, item) in dockItems.enumerated() {
            if let view = dockScrubber.itemViewForItem(at: index) as? DockItemView {
                view.set(icon: item.icon)
                view.set(isRunning: item.isRunning)
                view.set(isFrontmost: item.isFrontmost)
                if item.isFrontmost {
                    dockScrubber.scrollItem(at: index, to: .none)
                }
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
        if scrubber == persistentScrubber {
            return persistentItems.count
        }
        return dockItems.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let item = scrubber == persistentScrubber ? persistentItems[index] : dockItems[index]
        let view = scrubber.makeItem(withIdentifier: Constants.kDockItemView, owner: self) as! DockItemView
        view.set(icon:         item.icon)
        view.set(hasBadge:     item.hasBadge)
        view.set(isRunning:    item.isRunning)
        view.set(isFrontmost:  item.isFrontmost)
        return view
    }
}

extension DockWidget: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        let item = dockItems[selectedIndex]
        dockRepository.launch(bundleIdentifier: item.bundleIdentifier, completion: { success in
            NSLog("[Pock]: Did open: \(item.bundleIdentifier ?? item.path?.absoluteString ?? "Unknown") [success: \(success)]")
        })
        scrubber.selectedIndex = -1
    }
}
