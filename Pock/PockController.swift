//
//  PockController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import CoreGraphics
import Magnet
import SnapKit
import Defaults

/// Custom identifiers
@available(OSX 10.12.2, *)
extension NSTouchBarItem.Identifier {
    static let pockSystemIcon     = NSTouchBarItem.Identifier("com.pigigaldi.pock.pockSystemIcon")
    static let dockScrollableView = NSTouchBarItem.Identifier("com.pigigaldi.pock.dockScrollableView")
    static let escButton          = NSTouchBarItem.Identifier("com.pigigaldi.pock.escButton")
}

/// Known identifiers
public let kFinderIdentifier: String = "com.apple.finder"

/// Public utitlities
public func executeWithDelay(delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: UInt64(delay * Double(NSEC_PER_SEC))), execute: closure)
}

/// PockController
@available(OSX 10.12.2, *)
final class PockController: NSObject {
    
    /// Singleton
    public static let shared: PockController = PockController()
    
    /// Core
    fileprivate var notificationBadgeRefreshTimer: Timer!
    
    /// UI
    fileprivate let dockScrollView: NSScrollView = NSScrollView(frame: .zero)
    fileprivate let dockContentView: NSView = NSView(frame: .zero)
    
    /// Touch Bar
    fileprivate var pockTouchBar: NSTouchBar?
    
    /// Dock icons scrubber
    fileprivate static var pockDockIconsScrubber: NSScrubber?
    
    /// Dock's list array
    fileprivate var dockItems: [PockItem] = []
    
    /// Hide initializer
    override private init() {}
    
    /// Load Pock
    public func loadPock() {
        
        /// Init touch bar
        self.initTouchBar()
        
        /// Initialize global hotkey.
        self.initializeHotKey()
        
        /// Load data
        self.loadData()
        
        /// Start timer
        self.setupNotificationBadgeRefreshTimer()
        
        /// Register for notification
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.startLaunchAnimation(notification:)),
                                                          name: NSWorkspace.willLaunchApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.stopLaunchAnimation(notification:)),
                                                          name: NSWorkspace.didLaunchApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.loadData),
                                                          name: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.setupNotificationBadgeRefreshTimer),
                                                          name: .didChangeNotificationBadgeRefreshRate,
                                                          object: nil)
    }
    
    /// Load data
    @objc private func loadData() {
        
        /// Remove all
        self.dockItems.removeAll()
        
        /// Get dock persistent apps list
        self.dockItems += PockUtilities.getDockPersistentAppsList()
        
        // Get running apps for additional missing icon and active-badge
        self.dockItems += PockUtilities.getMissingRunningApps()
        
        /// Get dock persistent others list
        self.dockItems += PockUtilities.getDockPersistentOthersList()
        
        /// Display icons
        executeWithDelay(delay: 0.001, closure: { [weak self] in
            self?.displayIconsInScrollView()
        })
        
    }
    
    /// Update notification badge refresh timer
    @objc private func setupNotificationBadgeRefreshTimer() {
        
        /// Get refresh rate
        let refreshRate = defaults[.notificationBadgeRefreshInterval]
        
        /// Invalidate last timer
        self.notificationBadgeRefreshTimer?.invalidate()
        
        /// Set timer
        self.notificationBadgeRefreshTimer = Timer.scheduledTimer(withTimeInterval: refreshRate.rawValue, repeats: true, block: {  [unowned self] _ in
            
            /// Log
            NSLog("[Pock]: Refreshing notification badge... (rate: %@)", refreshRate.toString())
            
            /// Reload badge and running dot
            DispatchQueue.main.async {
                self.reloadBadgesAndRunningDot()
            }
            
        })
        
    }
    
    /// Start launch animation
    @objc private func startLaunchAnimation(notification: NSNotification) {
        guard let bundleIdentifier = notification.userInfo?["NSApplicationBundleIdentifier"] as? String else { return }
        let iconView = self.dockContentView.subviews.first(where: { ($0 as? PockItemView)?.dockItem?.bundleIdentifier == bundleIdentifier }) as? PockItemView
        iconView?.startBounceAnimation()
    }
    
    /// Stop launch animation
    @objc private func stopLaunchAnimation(notification: NSNotification) {
        guard let bundleIdentifier = notification.userInfo?["NSApplicationBundleIdentifier"] as? String else { return }
        let iconView = self.dockContentView.subviews.first(where: { ($0 as? PockItemView)?.dockItem?.bundleIdentifier == bundleIdentifier }) as? PockItemView
        iconView?.stopBounceAnimation()
    }
    
    /// Reload badges and running dot
    @objc private func reloadBadgesAndRunningDot() {
        
        /// Iterate on dock content view
        for subview in self.dockContentView.subviews {
            
            /// Check if is `PockItemView`
            guard let itemView = subview as? PockItemView else { continue }
            
            /// Update UI
            itemView.reloadUI()
            
        }
        
    }
    
    /// Display icons in scroll view
    private func displayIconsInScrollView() {
        
        /// Mark all icons as "to be updated"
        for iconView in self.dockContentView.subviews {
            guard let iconView = iconView as? PockItemView else { continue }
            iconView.dockItem = nil
        }
        
        /// Iterate on dockItems
        for (index, dockItem) in self.dockItems.enumerated() {
            
            /// Check for icon view
            if index < self.dockContentView.subviews.count, let itemView = self.dockContentView.subviews[index] as? PockItemView {
                itemView.dockItem = dockItem
                continue
            }
            
            /// Get icon view
            let itemView = PockItemView()
            itemView.dockItem = dockItem
            
            /// Add dockView to scroll view
            self.dockContentView.addSubview(itemView)
            
            /// Change x position
            itemView.frame.origin.x = 50 * CGFloat(index)
            
        }
        
        /// Remove un-needed icons
        for iconView in self.dockContentView.subviews {
            guard let iconView = iconView as? PockItemView, iconView.dockItem == nil else { continue }
            iconView.removeFromSuperview()
        }
        
        /// Update dockContentView content size
        self.dockContentView.frame.size.width = 50 * CGFloat(self.dockItems.count)
        self.dockContentView.frame.size.height = self.dockScrollView.frame.height
        
        /// Set dockContentView as scrollView's documentView
        if self.dockScrollView.documentView != self.dockContentView {
            self.dockScrollView.documentView = self.dockContentView
        }
        
    }
    
    /// Initialize Touch Bar
    private func initTouchBar() {
        
        /// Present
        self.presentPock()
        
        /// Show close box on left
        DFRSystemModalShowsCloseBoxWhenFrontMost(true)
        
        /// Add Pock to control strip
        let pockItem = NSCustomTouchBarItem(identifier: .pockSystemIcon)
        pockItem.view = NSButton(image: #imageLiteral(resourceName: "pock-inner-icon"), target: self, action: #selector(presentPock))
        
        /// Add system icon to control strip
        NSTouchBarItem.addSystemTrayItem(pockItem)
        
    }
    
    /// Present pock as system touch bar
    @objc private func presentPock() {
        
        /// Present dock in touch bar
        if #available (macOS 10.14, *) {
            NSTouchBar.presentSystemModalTouchBar(self.touchBar(), systemTrayItemIdentifier: NSTouchBarItem.Identifier.pockSystemIcon)
        } else {
            NSTouchBar.presentSystemModalFunctionBar(self.touchBar(), systemTrayItemIdentifier: NSTouchBarItem.Identifier.pockSystemIcon)
        }
        
    }
    
    /// Add global hotkey for setting Pock as top-most-application
    private func initializeHotKey() {
        
        /// Create HotKey
        if let keyCombo = KeyCombo(keyCode: 35, cocoaModifiers: [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.option]) {
            let hotKey = HotKey(identifier: "CommandP", keyCombo: keyCombo, target: self, action: #selector(self.addPockItemToControlStrip))
            let _ = HotKeyCenter.shared.register(with: hotKey)
        }
        
    }
    
    @objc fileprivate func escButtonSender() {
        let escSender = ESCKeySender()
        escSender.send()
    }
    
    @objc fileprivate func addPockItemToControlStrip() {
        self.presentPock()
    }
    
}

@available(OSX 10.12.2, *)
extension PockController: NSTouchBarDelegate {
    
    func touchBar() -> NSTouchBar? {
        guard self.pockTouchBar == nil else { return self.pockTouchBar }
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.escButton, .dockScrollableView]
        self.pockTouchBar = touchBar
        return self.pockTouchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        
        switch identifier {
        case NSTouchBarItem.Identifier.escButton:
            
            /// Return esc button item
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSButton(title: "esc", target: self, action: #selector(self.escButtonSender))
            return item
            
        case NSTouchBarItem.Identifier.dockScrollableView:
            
            /// Create custom item
            let item = NSCustomTouchBarItem(identifier: identifier)
            
            /// Get scroll view
            self.dockScrollView.backgroundColor = NSColor.black
            item.view = self.dockScrollView
            
            /// Stop here
            return item
            
        case NSTouchBarItem.Identifier.pockSystemIcon:
            
            /// Return Pock system item
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSButton(image: #imageLiteral(resourceName: "pock-inner-icon"), target: self, action: #selector(self.addPockItemToControlStrip))
            return item
            
        default:
            return nil
        }
        
    }
    
}
