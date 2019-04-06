//
//  DockItemView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import SnapKit

class DockItemView: NSScrubberItemView {
    
    /// Core
    private var isBounching: Bool = false
    
    /// UI
    private var contentView: NSView!
    private var iconView:    NSImageView!
    private var dotView:     NSView!
    private var badgeView:   NSTextField!
    
    /// Data
    public var dockItem: DockItem! { didSet { DispatchQueue.main.async { [weak self] in self?.reload() } } }
    
    /// Init
    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: .zero, size: Constants.dockItemSize))
        
        self.contentView = NSView(frame: .zero)
        self.contentView.layer?.backgroundColor = NSColor.red.cgColor
        
        self.iconView = NSImageView(frame: .zero)
        self.iconView.imageScaling = .scaleProportionallyDown
        
        self.contentView.addSubview(self.iconView)
        self.addSubview(self.contentView)
        
        self.contentView.snp.makeConstraints({ m in
            m.edges.equalToSuperview()
        })
        self.iconView.snp.makeConstraints({ m in
            m.edges.equalToSuperview()
        })
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(item: DockItem) {
        self.init(frame: .zero)
        self.dockItem = item
    }
    
    /// Reload
    public func reload() {
        reloadIcon()
    }
    
    private func reloadIcon() {
        iconView.image = dockItem.icon
    }
    
}
