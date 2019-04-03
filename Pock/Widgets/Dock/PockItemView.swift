//
//  PockItemView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/09/17.
//  Copyright © 2017 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import SnapKit

public class PockItemView: NSView {
    
    /// Core
    private static let kBounceAnimationKey: String = "kBounceAnimationKey"
    private var isBouncing: Bool = false
    
    /// UI
    private var contentView: NSView!
    private var iconView: NSImageView? = nil
    private var dotView: NSView!
    private var dotSize: CGFloat = 2.5
    private var badgeView: NSTextField!
    private var badgeSize: CGFloat = 10
    
    /// Data
    public var dockItem: PockItem? {
        didSet {
            /// Update is running UI
            self.reloadUI()
        }
    }
    
    /// Reload
    public func reloadUI() {
        /// Update icon
        self.initIconView()
        /// Update running dot
        self.updateRunningDot()
        /// Update badge
        self.updateBadge()
        /// Check for trash
        if self.dockItem?.label == "Trash" {
            self.updateIconIfItemIsTrash()
        }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: 40, height: 30)))
        self.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 40, height: 30))
        self.contentView.layer?.cornerRadius = 3.6
        self.contentView.layer?.backgroundColor = CGColor.init(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
        self.contentView.wantsLayer = true
        self.addSubview(contentView)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initIconView() {
    
        /// Check for icon
        guard let icon = self.dockItem?.icon else {
            self.iconView?.image = nil
            return
        }
        
        /// Check if iconView is initialized
        if let iconView = self.iconView {
            iconView.image = icon
            return
        }
        
        /// Init icon view
        self.iconView = NSImageView(image: icon)
        self.contentView.addSubview(self.iconView!)
        self.iconView?.snp.remakeConstraints({ make in
            make.size.width.equalTo(25)
            make.size.height.equalTo(25)
            make.centerX.equalToSuperview()
            make.top.equalTo(1)
        })
    
    }
    
    private func updateIconIfItemIsTrash() {
        Timer(timeInterval: 2, repeats: true, block: { [weak self] _ in
            let isTrashEmpty      = (try? FileManager.default.contentsOfDirectory(atPath: PockUtilities.default.trashPath).isEmpty) ?? true
            self?.dockItem?.icon  = PockUtilities.default.getIcon(orType: isTrashEmpty ? "TrashIcon" : "FullTrashIcon")
            DispatchQueue.main.async { [weak self] in self?.iconView?.image = self?.dockItem?.icon }
        }).fire()
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
            self.contentView.addSubview(self.dotView)
            self.dotView.snp.makeConstraints({ make in
                make.size.width.equalTo(self.dotSize)
                make.size.height.equalTo(self.dotSize)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(-1)
            })
        }
        
        /// Check if is frontmostApplication
        if self.dockItem?.isFrontmostApplication ?? false {
            self.contentView.wantsLayer = true
            self.contentView.layer?.cornerRadius = 3.6
            self.contentView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.4).cgColor
        }else {
            self.contentView.wantsLayer = false
            self.contentView.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
    }
    
    private func updateBadge() {
        
        /// Remove badge label
        self.badgeView?.removeFromSuperview()
        
        /// Check if item has badge
        if self.dockItem?.hasBadge ?? false {
            self.badgeView = NSTextField(frame: .zero)
            self.badgeView.wantsLayer = true
            self.badgeView.backgroundColor = .red
            self.badgeView.layer?.cornerRadius = self.badgeSize / 2
            self.badgeView.layer?.opacity = 0.9
            self.contentView.addSubview(self.badgeView)
            self.badgeView.snp.makeConstraints({ make in
                make.size.width.equalTo(self.badgeSize)
                make.size.height.equalTo(self.badgeSize)
                make.right.equalTo(-(self.badgeSize / 1.35))
                make.top.equalTo(0.15)
            })
        }

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
            
            /// Check if is frontmost
            if self.dockItem?.isFrontmostApplication ?? false {
                /// TODO: Find a way to minimize other apps from Pock
            }else {
                /// Launch application
                PockUtilities.default.launch(bundleIdentifier: self.dockItem!.bundleIdentifier, completion: { _ in })
            }
        
        }
        
    }
    
}

extension PockItemView: CAAnimationDelegate {
    func startBounceAnimation() {
        if !isBouncing {
            self.loadBounceAnimation()
        }
    }
    private func loadBounceAnimation() {
        isBouncing                   = true
        let bounce                   = CABasicAnimation(keyPath: "position.y")
        bounce.delegate              = self
        bounce.fromValue             = (self.iconView?.layer?.position.y ?? 0) + 3
        bounce.toValue               = (bounce.fromValue as? Float ?? 0) + 6
        bounce.duration              = 0.3
        bounce.autoreverses          = true
        self.iconView?.layer?.add(bounce, forKey: PockItemView.kBounceAnimationKey)
    }
    func stopBounceAnimation() {
        self.iconView?.layer?.removeAnimation(forKey: PockItemView.kBounceAnimationKey)
        self.isBouncing = false
    }
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            self.loadBounceAnimation()
        }
    }
}
