//
//  NowPlayingView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 14/12/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

fileprivate let playIconName  = NSImage.touchBarPlayTemplateName
fileprivate let pauseIconName = NSImage.touchBarPauseTemplateName
fileprivate let previousIcon = NSImage(named: NSImage.touchBarRewindTemplateName)!
fileprivate let nextIcon     = NSImage(named: NSImage.touchBarFastForwardTemplateName)!

class NowPlayingView: PKView {
    
    public  let itemView: NowPlayingItemView = NowPlayingItemView(frame: .zero, leftToRight: true)
    private var playPauseButton: NSButton? = nil
    private var previousButton:  NSButton!
    private var nextButton:      NSButton!
    
    public var style: NowPlayingWidgetStyle = Defaults[.nowPlayingWidgetStyle] {
        didSet {
            configureUIElements()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 30))
        self.configureUIElements()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configureUIElements()
    }
    
    @objc private func togglePlayPause() {
        NowPlayingHelper.shared.togglePlayingState()
    }
    
    @objc private func skipToNextItem() {
        NowPlayingHelper.shared.skipToNextTrack()
    }
    
    @objc private func skipToPreviousItem() {
        NowPlayingHelper.shared.skipToPreviousTrack()
    }
    
    public func updateWithItem(_ item: NowPlayingItem?) {
        itemView.nowPLayingItem = item
        DispatchQueue.main.async { [weak self, weak item] in
            self?.playPauseButton?.image = NSImage(named: item?.isPlaying ?? false ? pauseIconName : playIconName)
        }
    }
    
    private func configureUIElements() {
        subviews.forEach({ $0.removeFromSuperview() })
        previousButton = NSButton(image: previousIcon, target: self, action: #selector(skipToPreviousItem))
        previousButton.bezelColor = .black
        previousButton.snp.makeConstraints({ m in
            m.width.equalTo(32)
        })
        nextButton = NSButton(image: nextIcon, target: self, action: #selector(skipToNextItem))
        nextButton.bezelColor = .black
        nextButton.snp.makeConstraints({ m in
            m.width.equalTo(32)
        })
        switch style {
        case .playPause:
            let icon = NSImage(named: itemView.nowPLayingItem?.isPlaying ?? false ? pauseIconName : playIconName)!
            playPauseButton = NSButton(image: icon, target: self, action: #selector(togglePlayPause))
            playPauseButton?.bezelColor = .black
            playPauseButton?.snp.makeConstraints({ m in
                m.width.equalTo(32)
            })
        case .default:
            playPauseButton = nil
        case .onlyInfo:
            playPauseButton = nil
            previousButton  = nil
            nextButton      = nil
        }
        configureStackView()
        setupGestureHandlers()
    }
    
    private func configureStackView() {
        let views: [NSView]
        switch style {
        case .default:
            views = [previousButton, itemView, nextButton]
        case .playPause:
            views = [previousButton, playPauseButton!, nextButton]
        case .onlyInfo:
            views = [itemView]
        }
        let stackView = NSStackView(views: views)
        stackView.alignment = .centerY
        stackView.distribution = .fill
        stackView.spacing = 6
        addSubview(stackView)
        stackView.snp.makeConstraints({ m in
            m.left.top.right.bottom.equalToSuperview()
        })
    }
    
    private func setupGestureHandlers() {
        switch self.style {
        case .playPause:
            itemView.didTap        = nil
            itemView.didSwipeLeft  = nil
            itemView.didSwipeRight = nil
        
        case .default, .onlyInfo:
            itemView.didTap = { [unowned self] in
                self.togglePlayPause()
            }
            itemView.didSwipeLeft = { [unowned self] in
                self.skipToPreviousItem()
            }
            itemView.didSwipeRight = { [unowned self] in
                self.skipToNextItem()
            }
        }
    }
    
    override func didLongPressHandler() {
        guard let id = self.itemView.nowPLayingItem?.appBundleIdentifier else {
            return
        }
        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: id,
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }
    
}
