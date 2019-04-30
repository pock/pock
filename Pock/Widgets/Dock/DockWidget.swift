//
//  DockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class DockWidget: PockWidget {
    
    /// Core
    private var dockRepository: DockRepository!
    
    /// UI
    private var stackView:          NSStackView = NSStackView(frame: .zero)
    private var dockScrubber:       NSScrubber  = NSScrubber(frame: NSRect(x: 0, y: 0, width: 200,  height: 30))
    private var separator:          NSView      = NSView(frame:     NSRect(x: 0, y: 0, width: 1,    height: 20))
    private var persistentScrubber: NSScrubber  = NSScrubber(frame: NSRect(x: 0, y: 0, width: 50,   height: 30))
    
    /// Data
    private var dockItems:       [DockItem] = []
    private var persistentItems: [DockItem] = []
    
    /// Custom init
    override func customInit() {
        self.customizationLabel = "Dock"
        self.configureStackView()
        self.configureDockScrubber()
        self.configureSeparator()
        self.configurePersistentScrubber()
        self.displayScrubbers()
        self.set(view: stackView)
        self.dockRepository = DockRepository(delegate: self)
        self.dockRepository.reload(nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(displayScrubbers), name: .shouldReloadPersistentItems, object: nil)
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    /// Configure stack view
    private func configureStackView() {
        stackView.alignment = .centerY
        stackView.orientation = .horizontal
        stackView.distribution = .fill
    }
    
    @objc private func displayScrubbers() {
        self.separator.isHidden          = defaults[.hidePersistentItems] || persistentItems.isEmpty
        self.persistentScrubber.isHidden = defaults[.hidePersistentItems] || persistentItems.isEmpty
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
            m.width.equalTo((Constants.dockItemSize.width + 8) * CGFloat(persistentItems.count))
        })
        stackView.addArrangedSubview(persistentScrubber)
    }
    
}

extension DockWidget: DockDelegate {
    func didUpdate(apps: [DockItem]) {
        update(scrubber: dockScrubber, old_items: dockItems, new_items: apps, completion: { [weak self] items in
            self?.dockItems = items
            self?.dockScrubber.needsLayout = true
        })
    }
    func didUpdate(items: [DockItem]) {
        update(scrubber: persistentScrubber, old_items: persistentItems, new_items: items, canReload: true, completion: { [weak self] items in
            self?.persistentItems = items
            self?.displayScrubbers()
            persistentScrubber.snp.updateConstraints({ m in
                m.width.equalTo((Constants.dockItemSize.width + 8) * CGFloat(persistentItems.count))
            })
        })
    }
    private func update(scrubber: NSScrubber?, old_items: [DockItem], new_items: [DockItem], canReload: Bool = false, completion: ([DockItem]) -> Void) {
        guard let scrubber = scrubber else {
            completion(new_items)
            return
        }
        scrubber.performSequentialBatchUpdates {
            var count = scrubber.numberOfItems
            for (index, old_item) in old_items.enumerated() {
                if !new_items.contains(old_item) {
                    scrubber.removeItems(at: IndexSet(integer: index))
                    count -= 1
                }else {
                    if canReload {
                        scrubber.reloadItems(at: IndexSet(integer: index))
                    }
                }
            }
            for new_item in new_items {
                if !old_items.contains(new_item) {
                    scrubber.insertItems(at: IndexSet(integer: count))
                    if old_items.count > 0 {
                        scrubber.scrollItem(at: count - 1, to: .leading)
                    }
                    count += 1
                }
            }
            completion(new_items)
        }
    }
    func didUpdateBadge(for apps: [DockItem]) {
        for (index, item) in dockItems.enumerated() {
            if let view = dockScrubber.itemViewForItem(at: index) as? DockItemView {
                view.set(hasBadge: item.hasBadge)
            }
        }
    }
    func didUpdateRunningState(for apps: [DockItem]) {
        for (index, item) in dockItems.enumerated() {
            if let view = dockScrubber.itemViewForItem(at: index) as? DockItemView {
                view.set(icon: item.icon)
                view.set(isRunning: item.isRunning)
                view.set(isFrontmost: item.isFrontmost)
            }
        }
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
        let item = scrubber == persistentScrubber ? persistentItems[selectedIndex] : dockItems[selectedIndex]
        dockRepository.launch(bundleIdentifier: item.bundleIdentifier ?? item.path?.absoluteString, completion: { success in
            NSLog("[Pock]: Did open: \(item.bundleIdentifier ?? item.path?.absoluteString ?? "Unknown") [success: \(success)]")
        })
        scrubber.selectedIndex = -1
    }
}
