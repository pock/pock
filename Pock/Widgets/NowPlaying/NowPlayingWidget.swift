//
//  NowPlayingWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import PockKit

class NowPlayingWidget: PKWidget {
    
    var identifier: NSTouchBarItem.Identifier = NSTouchBarItem.Identifier.nowPlaying
    var customizationLabel: String            = "Now Playing".localized
    var view: NSView!
    
    /// UI
    private var nowPlayingItemView: NowPlayingItemView!
    
    required init() {
        self.updateNowPLayingItemView()
        self.registerForNotifications()
        self.setGestureHandlers()
        self.view = nowPlayingItemView
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
            nowPlayingItemView = NowPlayingItemView(leftToRight: true)
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
    }
    
}
