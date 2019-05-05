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
    @IBOutlet private weak var folderName: NSTextField!
    @IBOutlet private weak var scrubber:   NSScrubber!
    
    /// Core
    private let dockFolderRepository: DockFolderRepository = DockFolderRepository()
    private var folderUrl: URL!
    private var elements: [DockFolderItem] = []
    
    override func present() {
        guard folderUrl != nil else { return }
        self.loadElements()
        super.present()
        self.folderName.stringValue = folderUrl?.lastPathComponent ?? "??"
    }
    
    override func didLoad() {
        scrubber.register(DockFolderItemView.self, forItemIdentifier: Constants.kDockFolterItemView)
    }
    
    @IBAction func willDismiss(_ button: NSButton?) {
        self.dismiss()
    }
    
    @IBAction func willOpen(_ button: NSButton?) {
        NSWorkspace.shared.open(folderUrl)
        self.dismiss()
    }
    
}

extension DockFolderController {
    private func loadElements(reloadScrubber: Bool = true) {
        elements = dockFolderRepository.getItems(in: folderUrl)
        if reloadScrubber { scrubber.reloadData() }
    }
    public func set(folderUrl: URL) {
        self.folderUrl = folderUrl
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
        print("[DockFolderController]: Did select item at: \(selectedIndex)")
    }
}
