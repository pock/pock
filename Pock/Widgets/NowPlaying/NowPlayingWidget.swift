//
//  NowPlayingWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class NowPlayingWidget: PockWidget {
    
    /// UI
    private var nowPlayingItemView: NowPlayingItemView!
    
    override func customInit() {
        self.customizationLabel = "Now Playing"
        self.updateNowPLayingItemView()
        self.registerForNotifications()
        self.setGestureHandlers()
        self.set(view: nowPlayingItemView)
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateNowPLayingItemView),
                                               name: NowPlayingHelper.kNowPlayingItemDidChange,
                                               object: nil
        )
    }
    
    @objc private func updateNowPLayingItemView() {
        if nowPlayingItemView == nil {
            nowPlayingItemView = NowPlayingItemView(frame: .zero)
        }
        nowPlayingItemView.nowPLayingItem = NowPlayingHelper.shared.nowPlayingItem
    }
    
    private func setGestureHandlers() {
        nowPlayingItemView.didTap = {
            NowPlayingHelper.shared.togglePlayingState()
        }
        nowPlayingItemView.didSwipeLeft = {
            NowPlayingHelper.shared.skipToPreviousTrack()
        }
        nowPlayingItemView.didSwipeRight = {
            NowPlayingHelper.shared.skipToNextTrack()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NowPlayingHelper.shared.nowPlayingItem = nil
    }
    
}
