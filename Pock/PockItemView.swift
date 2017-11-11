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
public class PockItemView: NSView {
    
    /// UI
    private var iconView: NSImageView? = nil
    private var dotView: NSView!
    private var dotSize: CGFloat = 2.5
    
    /// Data
    public var dockItem: DockItem? {
        didSet {
            
            /// Set icon
            self.initIconView()
            
            /// Update is running UI
            self.updateRunningDot()
            
        }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: 40, height: 30)))
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initIconView() {
    
        /// Init icon view
        self.iconView = NSImageView(image: self.dockItem?.icon ?? NSImage(size: .zero))
        self.addSubview(self.iconView!)
        self.iconView?.snp.remakeConstraints({ make in
            make.size.width.equalTo(25)
            make.size.height.equalTo(25)
            make.centerX.equalToSuperview()
            make.top.equalTo(1)
        })
    
    }
    
    private func updateRunningDot() {
    
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
        
        /// Check if is frontmostApplication
        if self.dockItem?.isFrontmostApplication ?? false {
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.6).cgColor
        }else {
            self.wantsLayer = false
            self.layer?.backgroundColor = NSColor.clear.cgColor
        }
    
        /// Set corner radius
        self.layer?.cornerRadius = 3.6
        
    }
    
    override public func touchesEnded(with event: NSEvent) {
        
        /// Touches ended
        super.touchesEnded(with: event)
        
        /// Get touch
        guard let touch = event.allTouches().first else { return }
        
        /// Get touch location
        let location = touch.location(in: self.superview)
        
        /// Check if location is in self
        if self.frame.contains(location) {
        
            /// Launch application
            PockUtilities.launch(bundleIdentifier: self.dockItem!.bundleIdentifier, completion: { _ in })
        
        }
        
    }
    
}
