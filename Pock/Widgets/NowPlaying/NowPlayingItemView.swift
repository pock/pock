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
    
    private func updateContent() {
        
        var appBundleIdentifier: String = self.nowPLayingItem?.appBundleIdentifier ?? ""
        
        switch (appBundleIdentifier) {
        case "com.apple.WebKit.WebContent":
            appBundleIdentifier = "com.apple.Safari"
        case "com.spotify.client", "com.apple.iTunes", "com.apple.Safari","com.netease.163music","com.tencent.QQMusicMac":
            break
        default:
            appBundleIdentifier = "com.apple.iTunes"
        }
        
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: appBundleIdentifier)
        
        DispatchQueue.main.async { [weak self] in
            self?.imageView.image          = DockRepository.getIcon(forBundleIdentifier: appBundleIdentifier, orPath: path)
            self?.titleView.stringValue    = self?.nowPLayingItem?.title?.truncate(length: 20)  ?? "Pock"
            self?.subtitleView.stringValue = self?.nowPLayingItem?.artist?.truncate(length: 20) ?? FileManager.default.displayName(atPath: path ?? "Unknown")
            self?.updateForNowPlayingState()
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
