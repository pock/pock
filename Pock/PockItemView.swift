//
//  PockItemView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/09/17.
//  Copyright © 2017 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import SnapKit

@available(OSX 10.12.2, *)
public class PockItemView: NSScrubberItemView {
    
    /// UI
    private var iconView: NSImageView!
    private var dotView: NSView!
    private var dotSize: CGFloat = 2.5
    
    /// Data
    public var dockItem: DockItem? {
        didSet {
            self.updateContents()
        }
    }
    
    private func updateContents() {
        
        /// Init icon view
        self.iconView = NSImageView(image: self.dockItem?.icon ?? NSImage(size: .zero))
        self.addSubview(self.iconView!)
        self.iconView.snp.makeConstraints({ make in
            make.size.width.equalTo(25)
            make.size.height.equalTo(25)
            make.centerX.equalToSuperview()
            make.top.equalTo(1)
        })
        
        /// Remove dot icon
        self.dotView?.removeFromSuperview()
        
        /// Check if is running
        if self.dockItem?.isRunning ?? false {
            self.dotView = NSView(frame: .zero)
            self.dotView.wantsLayer = true
            self.dotView.layer?.backgroundColor = NSColor.white.cgColor
            self.dotView.layer?.cornerRadius = self.dotSize / 2
            self.addSubview(self.dotView)
            self.dotView.snp.makeConstraints({ make in
                make.size.width.equalTo(self.dotSize)
                make.size.height.equalTo(self.dotSize)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(-1)
            })
        }
        
        /// Set self frame size
        self.frame.size = NSSize(width: 30, height: 30)
    
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        self.iconView?.removeFromSuperview()
        self.dotView?.removeFromSuperview()
    }
    
}
