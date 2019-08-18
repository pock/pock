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

class NowPlayingItemView: PKDetailView {
    
    /// Overrideable
    public var didTap: (() -> Void)?
    public var didSwipeLeft: (() -> Void)?
    public var didSwipeRight: (() -> Void)?
    
    /// Data
    public var nowPLayingItem: NowPlayingItem? {
        didSet {
            self.updateContent()
        }
    }
    
    override func didLoad() {
        titleView.numberOfLoop    = 3
        subtitleView.numberOfLoop = 1
        super.didLoad()
    }
    
    private func updateContent() {
        
        var appBundleIdentifier: String = self.nowPLayingItem?.appBundleIdentifier ?? ""
        
        switch (appBundleIdentifier) {
        case "com.apple.WebKit.WebContent":
            appBundleIdentifier = "com.apple.Safari"
        case "com.spotify.client", "com.apple.iTunes", "com.apple.Safari", "com.netease.163music", "com.tencent.QQMusicMac", "com.apple.Music":
            break
        default:
            if #available(macOS 13, *) {
                appBundleIdentifier = "com.apple.Music"
            }else {
                appBundleIdentifier = "com.apple.iTunes"
            }
        }
        
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: appBundleIdentifier)
        
        DispatchQueue.main.async { [weak self] in
            self?.imageView.image = DockRepository.getIcon(forBundleIdentifier: appBundleIdentifier, orPath: path)
            
            let isPlaying = self?.nowPLayingItem?.isPlaying ?? false
            let title     = self?.nowPLayingItem?.title     ?? ""
            let artist    = self?.nowPLayingItem?.artist    ?? ""
            
            self?.shouldHideIcon = title.count < 1 && artist.count < 1
            
            let titleWidth    = (title  as NSString).size(withAttributes: self?.titleView.textFontAttributes    ?? [:]).width
            let subtitleWidth = (artist as NSString).size(withAttributes: self?.subtitleView.textFontAttributes ?? [:]).width
            self?.maxWidth = min(80, max(max(titleWidth, subtitleWidth), 1))
            
            self?.titleView.setup(string:    title)
            self?.subtitleView.setup(string: artist)
            
            self?.titleView.speed    = titleWidth    > 80 && isPlaying ? 4 : 0
            self?.subtitleView.speed = subtitleWidth > 80 && isPlaying ? 4 : 0
            
            self?.updateForNowPlayingState()
            self?.updateConstraint()
            self?.layoutSubtreeIfNeeded()
        }
    }
    
    private func updateForNowPlayingState() {
        if self.nowPLayingItem?.isPlaying ?? false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: { [weak self] in
                self?.startBounceAnimation()
            })
        }else {
            self.stopBounceAnimation()
        }
    }
    
    override open func didTapHandler() {
        self.didTap?()
    }
    
    override open func didSwipeLeftHandler() {
        self.didSwipeLeft?()
    }
    
    override open func didSwipeRightHandler() {
        self.didSwipeRight?()
    }
    
}
