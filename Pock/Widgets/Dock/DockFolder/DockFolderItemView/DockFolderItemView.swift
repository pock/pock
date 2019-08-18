//
//  DockFolderItemView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Cocoa

class DockFolderItemView: NSScrubberItemView {
    
    /// UI
    private var contentView:    NSView!
    private var frontmostView:  NSView!
    private var iconView:       NSImageView!
    private var nameLabel:      ScrollingTextView!
    private var detailLabel:    NSTextField!
    
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
        self.iconView.wantsLayer = true
        self.contentView.addSubview(self.iconView)
        self.iconView.snp.makeConstraints({ m in
            m.width.height.equalTo(Constants.dockItemIconSize)
            m.left.equalToSuperview().inset(2)
            m.centerY.equalToSuperview()
        })
    }
    
    /// Load name label
    private func loadNameLabel() {
        nameLabel = ScrollingTextView(frame: .zero)
        nameLabel.numberOfLoop     = 1
        nameLabel.autoresizingMask = .none
        nameLabel.font = NSFont.systemFont(ofSize: 9)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints({ m in
            m.left.equalTo(iconView.snp.right).offset(6)
            m.top.equalTo(iconView)
            m.right.equalToSuperview().inset(2)
            m.height.equalTo(iconView).dividedBy(2)
        })
    }
    
    /// Load detail label
    private func loadDetailLabel() {
        detailLabel = NSTextField(labelWithString: "")
        detailLabel.autoresizingMask = .none
        detailLabel.alignment = .left
        detailLabel.font = NSFont.systemFont(ofSize: 9)
        detailLabel.textColor = NSColor(calibratedRed: 124/255, green: 131/255, blue: 127/255, alpha: 1)
        contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints({ m in
            m.left.equalTo(nameLabel)
            m.top.equalTo(nameLabel.snp.bottom)
            m.right.equalToSuperview().inset(2)
            m.bottom.equalToSuperview().inset(2)
        })
    }
    
    /// Init
    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: .zero, size: Constants.dockItemSize))
        self.contentView = NSView(frame: .zero)
        self.loadIconView()
        self.loadNameLabel()
        self.loadDetailLabel()
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints({ m in
            m.edges.equalToSuperview()
        })
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            if frontmostView == nil { loadFrontmost() }
            frontmostView.layer?.backgroundColor = (isHighlighted ? NSColor.darkGray : NSColor.clear).cgColor
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.set(icon:   nil)
        self.set(name:   nil)
        self.set(detail: nil)
    }
    
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        layer?.contentsScale                = window?.backingScaleFactor ?? 1
        frontmostView?.layer?.contentsScale = window?.backingScaleFactor ?? 1
        iconView?.layer?.contentsScale      = window?.backingScaleFactor ?? 1
    }
    
    public func set(icon: NSImage?) {
        iconView.image = icon
    }
    
    public func set(name: String?) {
        nameLabel.speed = (name?.count ?? 0) <= 23 ? 0 : 4
        nameLabel.setup(string: name ?? "")
    }
    
    public func set(detail: String?) {
        detailLabel.stringValue = detail?.truncate(length: 20) ?? ""
    }
    
}
