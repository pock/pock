//
//  AppExposeItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 07/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Cocoa

typealias AppExposeItem = CGWindowItem

class AppExposeItemView: NSScrubberItemView {
    
    /// UI
    private var contentView:    NSView!
    private var preview:        NSImageView!
    private var nameLabel:      ScrollingTextView!
    
    /// Load icon view
    private func loadPreviewView() {
        self.preview = NSImageView(frame: .zero)
        self.preview.imageScaling = .scaleAxesIndependently
        self.preview.wantsLayer = true
        self.contentView.addSubview(self.preview)
        self.preview.snp.makeConstraints({ m in
            m.top.left.right.equalToSuperview()
        })
    }
    
    /// Load name label
    private func loadNameLabel() {
        nameLabel = ScrollingTextView(frame: .zero)
        nameLabel.autoresizingMask = .none
        nameLabel.font = NSFont.systemFont(ofSize: 6)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints({ m in
            m.left.right.equalToSuperview().inset(4)
            m.bottom.equalToSuperview()
            m.top.equalTo(preview.snp.bottom)
            m.height.equalTo(6)
        })
    }
    
    /// Init
    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: .zero, size: Constants.dockItemSize))
        self.contentView = NSView(frame: .zero)
        self.loadPreviewView()
        self.loadNameLabel()
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
        self.set(preview:   nil)
        self.set(name:   nil)
    }
    
    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        layer?.contentsScale                = window?.backingScaleFactor ?? 1
        preview?.layer?.contentsScale      = window?.backingScaleFactor ?? 1
    }
    
    public func set(preview: NSImage?) {
        self.preview.image = preview
    }
    
    public func set(name: String?) {
        nameLabel.setup(string: name ?? "")
    }
    
    public func set(minimized: Bool) {
        self.layer?.backgroundColor = minimized ? NSColor.red.cgColor : NSColor.clear.cgColor
    }
    
}
