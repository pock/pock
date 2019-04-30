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
    private var contentView:    NSView!
    private var frontmostView:  NSView!
    private var iconView:       NSImageView!
    private var dotView:        NSView!
    private var badgeView:      NSView!
    
    /// Load frontmost
    private func loadFrontmost() {
        self.frontmostView = NSView(frame: .zero)
        self.frontmostView.wantsLayer = true
        self.frontmostView.layer?.masksToBounds = true
        self.frontmostView.layer?.cornerRadius = Constants.dockItemCornerRadius
        self.contentView.addSubview(self.frontmostView, positioned: .below, relativeTo: self.iconView)
        self.frontmostView.snp.makeConstraints({ m in
            m.left.right.equalToSuperview()
            m.top.bottom.equalToSuperview()
        })
    }
    
    /// Load icon view
    private func loadIconView() {
        self.iconView = NSImageView(frame: .zero)
        self.iconView.imageScaling = .scaleProportionallyDown
        self.contentView.addSubview(self.iconView)
        self.iconView.snp.makeConstraints({ m in
            m.width.height.equalTo(Constants.dockItemIconSize)
            m.top.equalToSuperview().inset(2)
            m.centerX.equalToSuperview()
        })
    }
    
    /// Load dot view
    private func loadDotView() {
        self.dotView = NSView(frame: NSRect(origin: .zero, size: Constants.dockItemDotSize))
        self.dotView.wantsLayer = true
        self.dotView.layer?.cornerRadius = Constants.dockItemDotSize.width / 2
        self.dotView.layer?.backgroundColor = NSColor.lightGray.cgColor
        self.contentView.addSubview(self.dotView, positioned: .above, relativeTo: self.iconView)
        self.dotView.snp.makeConstraints({ m in
            m.width.height.equalTo(Constants.dockItemDotSize)
            m.bottom.equalToSuperview()
            m.centerX.equalToSuperview()
        })
    }
    
    /// Load badge view
    private func loadBadgeView() {
        self.badgeView = NSView(frame: NSRect(origin: .zero, size: Constants.dockItemBadgeSize))
        self.badgeView.wantsLayer = true
        self.badgeView.layer?.cornerRadius = Constants.dockItemBadgeSize.width / 2
        self.badgeView.layer?.backgroundColor = NSColor.red.cgColor
        self.contentView.addSubview(self.badgeView, positioned: .above, relativeTo: self.iconView)
        self.badgeView.snp.makeConstraints({ m in
            m.width.height.equalTo(Constants.dockItemBadgeSize.width)
            m.top.equalToSuperview().inset(1)
            m.centerX.equalToSuperview().offset(10)
        })
    }
    
    /// Init
    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: .zero, size: Constants.dockItemSize))
        self.contentView = NSView(frame: .zero)
        self.loadIconView()
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints({ m in
            m.edges.equalToSuperview()
        })
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.set(icon:         nil)
        self.set(hasBadge:     false)
        self.set(isRunning:    false)
        self.set(isFrontmost:  false)
    }
    
    public func set(icon: NSImage?) {
        iconView.image = icon
    }
    
    public func set(isFrontmost: Bool) {
        if frontmostView == nil { loadFrontmost() }
        frontmostView.layer?.backgroundColor = (isFrontmost ? NSColor.darkGray : NSColor.clear).cgColor
    }
    
    public func set(isRunning: Bool) {
        if dotView == nil { loadDotView() }
        dotView.isHidden = !isRunning
    }
    
    public func set(hasBadge: Bool) {
        if badgeView == nil { loadBadgeView() }
        badgeView.isHidden = !hasBadge
    }
    
}
