//
//  NowPlayingPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 14/12/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Preferences
import Defaults

class NowPlayingPreferencePane: NSViewController, PreferencePane {

    /// Preferenceable
    var preferencePaneIdentifier: Identifier = Identifier.now_playing_widget
    let preferencePaneTitle:      String     = "Now Playing Widget".localized
    var toolbarItemIcon:          NSImage {
        let id: String
        if #available(macOS 10.15, *) {
            id = "com.apple.Music"
        }else {
            id = "com.apple.iTunes"
        }
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: id)!
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    /// UI Elements
    @IBOutlet private weak var defaultRadioButton:   NSButton!
    @IBOutlet private weak var onlyInfoRadioButton:  NSButton!
    @IBOutlet private weak var playPauseRadioButton: NSButton!
    
    override var nibName: NSNib.Name? {
        return "NowPlayingPreferencePane"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch Defaults[.nowPlayingWidgetStyle] {
        case .default:
            defaultRadioButton.state = .on
        case .onlyInfo:
            onlyInfoRadioButton.state = .on
        case .playPause:
            playPauseRadioButton.state = .on
        }
    }
    
    @IBAction private func didSelectRadioButton(_ control: NSControl) {
        switch control.tag {
        case 0:
            Defaults[.nowPlayingWidgetStyle] = .default
            onlyInfoRadioButton.state  = .off
            playPauseRadioButton.state = .off
        case 1:
            Defaults[.nowPlayingWidgetStyle] = .onlyInfo
            defaultRadioButton.state   = .off
            playPauseRadioButton.state = .off
        case 2:
            Defaults[.nowPlayingWidgetStyle] = .playPause
            defaultRadioButton.state   = .off
            onlyInfoRadioButton.state  = .off
        default:
            return
        }
        NSWorkspace.shared.notificationCenter.post(name: .didChangeNowPlayingWidgetStyle, object: nil)
    }
    
}
