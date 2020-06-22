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
    
    
    private var artworkAPITask: URLSessionTask?
    private var artworkDownloadTask: URLSessionTask?
    
    var cachedAlbumArtName: String? = nil
    var cachedAlbumArt: NSImage? = nil
    
    func updateArtwork(search: String, completionHandler: @escaping (NSImage?) -> Void) {
        
        if (cachedAlbumArtName == search) {
            completionHandler(cachedAlbumArt)
            return
        }
        
        
        // Destroy tasks, if any was already busy
        if let previousAPITask = artworkAPITask {
            previousAPITask.cancel()
        }
        
        if let previousDownloadTask = artworkDownloadTask {
            previousDownloadTask.cancel()
        }
        
        // Start fetching artwork
        artworkAPITask = URLSession.fetchJSON(fromURL: URL(string: "https://itunes.apple.com/search?term=\(search)&entity=song&limit=1")!) { (data, json, error) in
            if error != nil {
                print("Could not get artwork")
                completionHandler(nil)
                return
            }

            if let json = json as? [String: Any] {
                if let results = json["results"] as? [[String: Any]] {
                    if results.count >= 1, let imgURL = results[0]["artworkUrl100"] as? String {
                        
                        // Create the URL
                        let url = URL(string: imgURL)!
                        
                        // Download the artwork
                        self.artworkDownloadTask = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                            
                            if error != nil {
                                completionHandler(nil)
                                return
                            }

                            DispatchQueue.main.async {
                                self.cachedAlbumArtName = search
                                self.cachedAlbumArt = NSImage(data: data!)
                                // Set the artwork to the image
                                completionHandler(self.cachedAlbumArt)
                            }
                        })
                            
                        self.artworkDownloadTask!.resume()
                    }
                    else {
                        completionHandler(nil)
                    }
                }
            }
        }
        
        artworkAPITask!.resume()
    }
    
    @objc private func updateMediaContent() {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.global(qos: .utility), { [weak self] info in
            self?.nowPlayingItem.title  = info?[kMRMediaRemoteNowPlayingInfoTitle]  as? String
            self?.nowPlayingItem.album  = info?[kMRMediaRemoteNowPlayingInfoAlbum]  as? String
            self?.nowPlayingItem.artist = info?[kMRMediaRemoteNowPlayingInfoArtist] as? String
            if info == nil {
                self?.nowPlayingItem.isPlaying = false
            }
            self?.nowPlayingItem.image = nil
            NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
            self?.updateArtwork(search: "\(self?.nowPlayingItem.title ?? "") \(self?.nowPlayingItem.artist ?? "")".replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) { image in
                self?.nowPlayingItem.image = image
                NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
            }
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

extension URLSession {
      static func fetchJSON(fromURL url: URL, completionHandler: @escaping (Data?, Any?, Error?) -> Void) -> URLSessionTask {
          let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
              // Error occurred during request
              if error != nil {
                  completionHandler(nil, nil, error)
                  return
              }
              
              let json = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments)

              completionHandler(data, json, nil)
          }
          
          return task
      }
  }

