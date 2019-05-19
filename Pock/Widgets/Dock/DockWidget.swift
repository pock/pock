//
//  DockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults
import DeepDiff

class DockWidget: PockWidget {
    
    /// Core
    private var dockRepository: DockRepository!
    private var operationQueue: OperationQueue?
    
    /// UI
    private var stackView:          NSStackView! = NSStackView(frame: .zero)
    private var dockScrubber:       NSScrubber!  = NSScrubber(frame: NSRect(x: 0, y: 0, width: 200,  height: 30))
    private var separator:          NSView!      = NSView(frame:     NSRect(x: 0, y: 0, width: 1,    height: 20))
    private var persistentScrubber: NSScrubber!  = NSScrubber(frame: NSRect(x: 0, y: 0, width: 50,   height: 30))
    
    /// Data
    private var dockItems:       [DockItem] = []
    private var persistentItems: [DockItem] = []
    private var cachedItemViews: [Int: DockItemView] = [:]
    
    /// Custom init
    override func customInit() {
        self.operationQueue = OperationQueue()
        self.operationQueue?.maxConcurrentOperationCount = 1
        self.operationQueue?.qualityOfService = .background
        
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
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(reloadDockScrubberLayout), name: .shouldReloadDockLayout, object: nil)
    }
    
    deinit {
        operationQueue?.cancelAllOperations()
        operationQueue      = nil
        stackView           = nil
        dockScrubber        = nil
        separator           = nil
        persistentScrubber  = nil
        dockRepository      = nil
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
    
    @objc private func reloadDockScrubberLayout() {
        let dockLayout              = NSScrubberFlowLayout()
        dockLayout.itemSize         = Constants.dockItemSize
        dockLayout.itemSpacing      = CGFloat(defaults[.itemSpacing])
        dockScrubber.scrubberLayout = dockLayout
        let persistentLayout              = NSScrubberFlowLayout()
        persistentLayout.itemSize         = Constants.dockItemSize
        persistentLayout.itemSpacing      = CGFloat(defaults[.itemSpacing])
        persistentScrubber.scrubberLayout = persistentLayout
    }
    
    /// Configure dock scrubber
    private func configureDockScrubber() {
        let layout = NSScrubberFlowLayout()
        layout.itemSize    = Constants.dockItemSize
        layout.itemSpacing = CGFloat(defaults[.itemSpacing])
        dockScrubber.dataSource = self
        dockScrubber.delegate = self
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
        layout.itemSize    = Constants.dockItemSize
        layout.itemSpacing = CGFloat(defaults[.itemSpacing])
        persistentScrubber.dataSource = self
        persistentScrubber.delegate = self
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
        update(scrubber: dockScrubber, oldItems: dockItems, newItems: apps) { [weak self] apps in
            apps.enumerated().forEach({ index, item in
                item.index = index
            })
            self?.dockItems = apps
        }
    }
    func didUpdate(items: [DockItem]) {
        update(scrubber: persistentScrubber, oldItems: persistentItems, newItems: items) { [weak self] items in
            self?.persistentItems = items
            self?.displayScrubbers()
            self?.persistentScrubber.snp.updateConstraints({ m in
                m.width.equalTo((Constants.dockItemSize.width + 8) * CGFloat(self?.persistentItems.count ?? 0))
            })
        }
    }
    
    @discardableResult
    private func updateView(for item: DockItem?) -> DockItemView? {
        guard let item = item else { return nil }
        var view: DockItemView! = cachedItemViews[item.diffId]
        if view == nil {
            view = DockItemView(frame: .zero)
            cachedItemViews[item.diffId] = view
        }
        view.clear()
        view.set(icon:        item.icon)
        view.set(hasBadge:    item.hasBadge)
        view.set(isRunning:   item.isRunning)
        view.set(isFrontmost: item.isFrontmost)
        return view
    }
    
    private func update(scrubber: NSScrubber?, oldItems: [DockItem], newItems: [DockItem], completion: (([DockItem]) -> Void)? = nil) {
        guard let scrubber = scrubber else {
            completion?(newItems)
            return
        }
        operationQueue?.addOperation {
            let diffs = diff(old: oldItems, new: newItems)
            DispatchQueue.main.async {
                scrubber.performSequentialBatchUpdates {
                    diffs.executeIfPresent({ [weak self] changes in
                        completion?(newItems)
                        guard changes.count < 2 else {
                            scrubber.reloadData()
                            return
                        }
                        for change in changes {
                            switch change {
                            case let .delete(delete):
                                self?.cachedItemViews.removeValue(forKey: delete.item.diffId)
                                scrubber.removeItems(at: IndexSet(integer: delete.index))
                                print("[Pock]: Removed '\(delete.item.bundleIdentifier ?? delete.item.path?.absoluteString ?? "unknown")' from: \(delete.index)")
                            case let .insert(insert):
                                scrubber.insertItems(at: IndexSet(integer: insert.index))
                                print("[Pock]: Inserted '\(insert.item.bundleIdentifier ?? insert.item.path?.absoluteString ?? "unknown")' at: \(insert.index)")
                            case let .replace(replace):
                                scrubber.reloadItems(at: IndexSet(integer: replace.index))
                                let old_id = replace.oldItem.bundleIdentifier ?? replace.oldItem.path?.absoluteString ?? "unknown old"
                                let new_id = replace.newItem.bundleIdentifier ?? replace.newItem.path?.absoluteString ?? "unknown new"
                                print("[Pock]: Replace '\(old_id)' with '\(new_id)' at: \(replace.index)")
                            case let .move(move):
                                scrubber.moveItem(at: move.fromIndex, to: move.toIndex)
                                print("[Pock]: Moved '\(move.item.bundleIdentifier ?? move.item.path?.absoluteString ?? "unknown")' from: '\(move.fromIndex)', to: \(move.toIndex)")
                            }
                        }
                    })
                }
            }
        }
    }
    func didUpdateBadge(for apps: [DockItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let s = self else { return }
            s.cachedItemViews.forEach({ key, view in
                view.set(hasBadge: apps.first(where: { $0.diffId == key })?.hasBadge ?? false)
            })
        }
    }
    func didUpdateRunningState(for apps: [DockItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let s = self else { return }
            s.cachedItemViews.forEach({ key, view in
                let item = apps.first(where: { $0.diffId == key })
                view.set(isRunning:   item?.isRunning   ?? false)
                view.set(isFrontmost: item?.isFrontmost ?? false)
                view.set(isLaunching: item?.isLaunching ?? false)
            })
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
        return updateView(for: item)!
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
