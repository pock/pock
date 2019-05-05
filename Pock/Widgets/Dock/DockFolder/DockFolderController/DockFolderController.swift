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
    
    deinit {
        if !isProd { print("[DockFolderController]: Deinit controller for path: \(folderUrl.path)") }
    }
    
    override func present() {
        guard folderUrl != nil else { return }
        self.loadElements()
        var defaultIdentifiers = touchBar?.defaultItemIdentifiers
        if !dockFolderRepository.shouldShowBackButton {
            defaultIdentifiers?.removeAll(where: { $0.rawValue == "BackButton" })
        }
        touchBar?.defaultItemIdentifiers = defaultIdentifiers ?? []
        super.present()
        self.setCurrentFolder(name: folderUrl?.lastPathComponent ?? "<missing name>")
        self.folderDetail.stringValue = "Loading..."
    }
    
    override func didLoad() {
        scrubber.register(DockFolderItemView.self, forItemIdentifier: Constants.kDockFolterItemView)
    }
    
    @IBAction func willClose(_ button: NSButton?) {
        dockFolderRepository.popToRootDockFolderController()
    }
    
    @IBAction func willDismiss(_ button: NSButton?) {
        dockFolderRepository.popDockFolderController()
    }
    
    @IBAction func willOpen(_ button: NSButton?) {
        NSWorkspace.shared.open(folderUrl)
        willClose(nil)
    }
    
}

extension DockFolderController {
    public func set(folderUrl: URL) {
        self.folderUrl = folderUrl
    }
    public func set(dockFolderRepository: DockFolderRepository) {
        self.dockFolderRepository = dockFolderRepository
    }
}

extension DockFolderController {
    private func loadElements(reloadScrubber: Bool = true) {
        dockFolderRepository.getItems(in: folderUrl) { [weak self] elements in
            self?.elements = elements
            self?.folderDetail.stringValue = "\(elements.count) elements"
            if reloadScrubber { self?.scrubber.reloadData() }
        }
    }
    private func setCurrentFolder(name: String) {
        self.folderName.stringValue = name == ".Trash" ? "Trash" : name.truncate(length: 30)
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
        dockFolderRepository.open(item: item) { success in
            NSLog("[DockFolderController]: Did open: \(item.path?.path ?? "<unknown>") [success: \(success)]")
        }
        scrubber.selectedIndex = -1
    }
}
