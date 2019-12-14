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
    private var nowPlayingView: NowPlayingView = NowPlayingView(frame: .zero)
    
    required init() {
        self.updateNowPLayingItemView()
        self.registerForNotifications()
        self.view = nowPlayingView
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateNowPLayingItemView),
                                               name: NowPlayingHelper.kNowPlayingItemDidChange,
                                               object: nil
        )
    }
    
    @objc private func updateNowPLayingItemView() {
        nowPlayingView.updateWithItem(NowPlayingHelper.shared.nowPlayingItem)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
