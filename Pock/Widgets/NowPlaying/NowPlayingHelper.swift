//
//  NowPlayingHelper.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class NowPlayingHelper {
    
    /// Core
    public static let shared: NowPlayingHelper = NowPlayingHelper()
    public static let kNowPlayingItemDidChange: Notification.Name = Notification.Name(rawValue: "kNowPlayingItemDidChange")
    
    /// Data
    public let nowPlayingItem: NowPlayingItem = NowPlayingItem()
    
    private init() {
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.global(qos: .utility))
        registerForNotifications()
        updateCurrentPlayingApp()
        updateMediaContent()
        updateCurrentPlayingState()
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateCurrentPlayingApp),
                                               name: NSNotification.Name.mrMediaRemoteNowPlayingApplicationDidChange,
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateMediaContent),
                                               name: NSNotification.Name(rawValue: kMRMediaRemoteNowPlayingApplicationClientStateDidChange),
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateMediaContent),
                                               name: NSNotification.Name.mrNowPlayingPlaybackQueueChanged,
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateMediaContent),
                                               name: NSNotification.Name.mrPlaybackQueueContentItemsChanged,
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateCurrentPlayingState),
                                               name: NSNotification.Name.mrMediaRemoteNowPlayingApplicationIsPlayingDidChange,
                                               object: nil
        )
    }
    
    @objc private func updateCurrentPlayingApp() {
        MRMediaRemoteGetNowPlayingClients(DispatchQueue.global(qos: .utility), { [weak self] clients in
            if let info = (clients as? [Any])?.last {
                if let appBundleIdentifier = MRNowPlayingClientGetBundleIdentifier(info) {
                    self?.nowPlayingItem.appBundleIdentifier = appBundleIdentifier
                }else if let appBundleIdentifier = MRNowPlayingClientGetParentAppBundleIdentifier(info) {
                    self?.nowPlayingItem.appBundleIdentifier = appBundleIdentifier
                }else {
                    self?.nowPlayingItem.appBundleIdentifier = nil
                }
            }else {
                self?.nowPlayingItem.appBundleIdentifier = nil
                self?.nowPlayingItem.isPlaying = false
                self?.nowPlayingItem.album  = nil
                self?.nowPlayingItem.artist = nil
                self?.nowPlayingItem.title  = nil
            }
            NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
        })
    }
    
    @objc private func updateMediaContent() {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.global(qos: .utility), { [weak self] info in
            self?.nowPlayingItem.title  = info?[kMRMediaRemoteNowPlayingInfoTitle]  as? String
            self?.nowPlayingItem.album  = info?[kMRMediaRemoteNowPlayingInfoAlbum]  as? String
            self?.nowPlayingItem.artist = info?[kMRMediaRemoteNowPlayingInfoArtist] as? String
            if info == nil {
                self?.nowPlayingItem.isPlaying = false
            }
            NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
        })
    }
    
    @objc private func updateCurrentPlayingState() {
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.global(qos: .utility), {[weak self] isPlaying in
            if self?.nowPlayingItem.appBundleIdentifier == nil {
                self?.nowPlayingItem.isPlaying = false
            }else {
                self?.nowPlayingItem.isPlaying = isPlaying
            }
            NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension NowPlayingHelper {
    
    public func togglePlayingState() {
        MRMediaRemoteSendCommand(kMRTogglePlayPause, nil)
    }
    
    public func skipToNextTrack() {
        MRMediaRemoteSendCommand(kMRNextTrack, nil)
    }
    
    public func skipToPreviousTrack() {
        MRMediaRemoteSendCommand(kMRPreviousTrack, nil)
    }
    
}
