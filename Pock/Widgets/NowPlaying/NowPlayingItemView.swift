//
//  NowPlayingItemView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import AppKit

extension String {
    func truncate(length: Int, trailing: String = "…") -> String {
        return self.count > length ? String(self.prefix(length)) + trailing : self
    }
}

class NowPlayingItemView: PockTappableView {
    
    /// Core
    private static let kBounceAnimationKey:   String = "kBounceAnimationKey"
    private var isAnimating: Bool = false
    
    public var didTap: (() -> Void)?
    public var didSwipeLeft: (() -> Void)?
    public var didSwipeRight: (() -> Void)?
    
    /// UI
    private var imageView:    NSImageView!
    private var titleView:    NSTextField!
    private var subtitleView: NSTextField!
    
    /// Data
    public var nowPLayingItem: NowPlayingItem? {
        didSet {
            self.updateContent()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        imageView = NSImageView(frame: .zero)
        imageView.autoresizingMask = .none
        imageView.imageScaling = .scaleProportionallyDown
        
        titleView = NSTextField(labelWithString: "")
        titleView.autoresizingMask = .none
        titleView.alignment = .left
        titleView.font = NSFont.systemFont(ofSize: 9)
        
        subtitleView = NSTextField(labelWithString: "")
        subtitleView.autoresizingMask = .none
        subtitleView.alignment = .left
        subtitleView.font = NSFont.systemFont(ofSize: 9)
        subtitleView.textColor = NSColor(calibratedRed: 124/255, green: 131/255, blue: 127/255, alpha: 1)
        
        addSubview(imageView)
        addSubview(titleView)
        addSubview(subtitleView)
        
        updateContent()
        updateLayout()
    }
    
    private func updateContent() {
        
        var appBundleIdentifier: String = self.nowPLayingItem?.appBundleIdentifier ?? ""
        
        switch (appBundleIdentifier) {
        case "com.apple.WebKit.WebContent":
            appBundleIdentifier = "com.apple.Safari"
        case "com.spotify.client", "com.apple.iTunes", "com.apple.Safari":
            break
        default:
            appBundleIdentifier = "com.apple.iTunes"
        }
        
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: appBundleIdentifier)
        
        DispatchQueue.main.async { [weak self] in
            self?.imageView.image          = DockRepository.getIcon(forBundleIdentifier: appBundleIdentifier, orPath: path)
            self?.titleView.stringValue    = self?.nowPLayingItem?.title?.truncate(length: 30) ?? "Pock"
            self?.subtitleView.stringValue = self?.nowPLayingItem?.artist ?? FileManager.default.displayName(atPath: path ?? "Unknown")
            self?.updateForNowPlayingState()
        }
    }
    
    private func updateForNowPlayingState() {
        if self.nowPLayingItem?.isPlaying ?? false {
            self.startBounceAnimation()
        }else {
            self.stopBounceAnimation()
        }
    }
    
    private func updateLayout() {
        imageView.snp.makeConstraints({ maker in
            maker.width.equalTo(24)
            maker.top.bottom.equalTo(self)
            maker.left.equalTo(self)
        })
        titleView.sizeToFit()
        titleView.snp.makeConstraints({ maker in
            maker.height.equalTo(titleView.frame.height)
            maker.left.equalTo(imageView.snp.right).offset(4)
            maker.top.equalTo(imageView).inset(4)
            maker.right.equalTo(self).inset(4)
        })
        subtitleView.sizeToFit()
        subtitleView.snp.makeConstraints({ maker in
            maker.left.equalTo(titleView)
            maker.top.equalTo(titleView.snp.bottom)
            maker.right.equalTo(titleView)
            maker.bottom.equalTo(self)
        })
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func didTapHandler() {
        self.didTap?()
    }
    
    override public func didSwipeLeftHandler() {
        self.didSwipeLeft?()
    }
    
    override public func didSwipeRightHandler() {
        self.didSwipeRight?()
    }
    
}

extension NowPlayingItemView {
    func startBounceAnimation() {
        if !isAnimating {
            self.loadBounceAnimation()
        }
    }
    private func loadBounceAnimation() {
        isAnimating                   = true
        
        let bounce                   = CABasicAnimation(keyPath: "transform.scale")
        bounce.fromValue             = 0.86
        bounce.toValue               = 1
        bounce.duration              = 1.2
        bounce.autoreverses          = true
        bounce.repeatCount           = Float.infinity
        bounce.timingFunction        = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        let frame = self.imageView.layer?.frame
        self.imageView.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.imageView.layer?.frame = frame ?? .zero
        self.imageView.layer?.add(bounce, forKey: NowPlayingItemView.kBounceAnimationKey)
    }
    func stopBounceAnimation() {
        self.imageView.layer?.removeAnimation(forKey: NowPlayingItemView.kBounceAnimationKey)
        self.isAnimating = false
    }
}
