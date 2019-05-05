//
//  DockFolderController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class DockFolderController: PockTouchBarController {
    
    /// UI
    @IBOutlet private weak var folderName:   NSTextField!
    @IBOutlet private weak var folderDetail: NSTextField!
    @IBOutlet private weak var scrubber:     NSScrubber!
    
    /// Core
    private var dockFolderRepository: DockFolderRepository!
    private var folderUrl: URL!
    private var elements: [DockFolderItem] = []
    private var childControllers: [DockFolderController] = []
    
    override func present() {
        guard folderUrl != nil else { return }
        self.loadElements()
        var defaultIdentifiers = touchBar?.defaultItemIdentifiers
        if dockFolderRepository.rootDockFolderController.childControllers.isEmpty {
            defaultIdentifiers?.removeAll(where: { $0.rawValue == "BackButton" })
        }
        touchBar?.defaultItemIdentifiers = defaultIdentifiers ?? []
        super.present()
        self.folderName.stringValue   = folderUrl?.lastPathComponent.truncate(length: 30) ?? "<missing name>"
        self.folderDetail.stringValue = "\(elements.count) elements"
    }
    
    override func didLoad() {
        scrubber.register(DockFolderItemView.self, forItemIdentifier: Constants.kDockFolterItemView)
    }
    
    @IBAction func willClose(_ button: NSButton?) {
        dockFolderRepository.rootDockFolderController.popToRootDockFolderController(shouldDismiss: true)
    }
    
    @IBAction func willDismiss(_ button: NSButton?) {
        dockFolderRepository.rootDockFolderController.popDockFolderController()
    }
    
    @IBAction func willOpen(_ button: NSButton?) {
        NSWorkspace.shared.open(folderUrl)
        willDismiss(nil)
    }
    
}

extension DockFolderController {
    public func set(folderUrl: URL) {
        self.folderUrl = folderUrl
    }
    public func set(dockFolderRepository: DockFolderRepository) {
        self.dockFolderRepository = dockFolderRepository
    }
    public func push(_ controller: DockFolderController) {
        childControllers.append(controller)
        controller.set(dockFolderRepository: dockFolderRepository)
        controller.present()
    }
    public func popDockFolderController() {
        guard let last = childControllers.popLast() else {
            self.dismiss()
            return
        }
        last.dismiss()
    }
    public func popToRootDockFolderController(shouldDismiss: Bool = false) {
        childControllers.reversed().forEach({ $0.popDockFolderController() })
        childControllers.removeAll()
        if shouldDismiss {
            self.dismiss()
        }
    }
}

extension DockFolderController {
    private func loadElements(reloadScrubber: Bool = true) {
        elements = dockFolderRepository.getItems(in: folderUrl)
        if reloadScrubber { scrubber.reloadData() }
    }
}

extension DockFolderController: NSScrubberDataSource {
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return elements.count
    }
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let item = elements[index]
        let view = scrubber.makeItem(withIdentifier: Constants.kDockFolterItemView, owner: self) as! DockFolderItemView
        view.set(icon:   item.icon)
        view.set(name:   item.name)
        view.set(detail: item.detail)
        return view
    }
}

extension DockFolderController: NSScrubberFlowLayoutDelegate {
    func scrubber(_ scrubber: NSScrubber, layout: NSScrubberFlowLayout, sizeForItemAt itemIndex: Int) -> NSSize {
        let item = elements[itemIndex]
        let font = NSFont.systemFont(ofSize: 10)
        let w = max(width(for: item.name?.truncate(length: 20), with: font), width(for: item.detail?.truncate(length: 20), with: font))
        return NSSize(width: w, height: 30)
    }
    private func width(for text: String?, with font: NSFont) -> CGFloat {
        let fontAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        let size = (text ?? "").size(withAttributes: fontAttributes)
        return max(30, Constants.dockItemIconSize.width + 8 + size.width)
    }
}

extension DockFolderController: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        let item = elements[selectedIndex]
        dockFolderRepository.open(item: item)
        scrubber.selectedIndex = -1
    }
}
