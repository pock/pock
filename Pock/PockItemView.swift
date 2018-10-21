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
    
    /// Core
    private static let kBounceAnimationKey: String = "kBounceAnimationKey"
    
    /// UI
    private var iconView: NSImageView? = nil
    private var dotView: NSView!
    private var dotSize: CGFloat = 2.5
    private var badgeView: NSTextField!
    private var badgeSize: CGFloat = 10
    private var shouldAnimate: Bool = false
    
    /// Data
    public var dockItem: PockItem? {
        didSet {
            /// Set icon
            self.initIconView()
            /// Update is running UI
            self.reloadUI()
        }
    }
    
    /// Reload
    public func reloadUI() {
        /// Update running dot
        self.updateRunningDot()
        /// Update badge
        self.updateBadge()
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: 40, height: 30)))
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
            self.addSubview(self.badgeView)
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
        
            /// Launch application
            PockUtilities.launch(bundleIdentifier: self.dockItem!.bundleIdentifier, completion: { _ in })
        
        }
        
    }
    
}

@available(OSX 10.12.2, *)
extension PockItemView: CAAnimationDelegate {
    func startBounceAnimation() {
        self.shouldAnimate = true
        self.loadBounceAnimation()
    }
    func loadBounceAnimation() {
        let bounce                   = CABasicAnimation(keyPath: "position.y")
        bounce.delegate              = self
        bounce.fromValue             = (self.iconView?.layer?.position.y ?? 0) + 3
        bounce.toValue               = (bounce.fromValue as? Float ?? 0) + 6
        bounce.duration              = 0.3
        bounce.autoreverses          = true
        self.iconView?.layer?.add(bounce, forKey: PockItemView.kBounceAnimationKey)
    }
    func stopBounceAnimation() {
        self.shouldAnimate = false
    }
    private func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if self.shouldAnimate {
            self.loadBounceAnimation()
        }
    }
}
