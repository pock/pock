//
//  DockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

fileprivate class DockWidgetView: NSStackView {
    override open var intrinsicContentSize: NSSize { return NSMakeSize(NSView.noIntrinsicMetric, NSView.noIntrinsicMetric) }
}

class DockWidget: PockWidget {
    
    /// Core
    fileprivate var notificationBadgeRefreshTimer: Timer!
    
    /// UI
    fileprivate var dockScrollView:  NSScrollView = NSScrollView(frame: .zero)
    fileprivate var dockContentView: NSView       = NSView(frame: .zero)
    
    /// Data
    fileprivate var itemViews:  [String: PockItemView] = [:]
    fileprivate var items:      [PockItem] {
        /// Returnable
        var returnable: [PockItem] = []
        /// Get dock persistent apps list
        returnable += PockUtilities.getDockPersistentAppsList()
        // Get running apps for additional missing icon and active-badge
        returnable += PockUtilities.getMissingRunningApps()
        /// Get dock persistent others list
        returnable += PockUtilities.getDockPersistentOthersList()
        /// Return
        return returnable
    }
    
    /// Custom init
    override func customInit() {
        self.customizationLabel = "Dock"
        self.dockScrollView.backgroundColor = .black
        self.dockScrollView.horizontalScrollElasticity = .allowed
        self.set(view: self.dockScrollView)
    }
    
    override func viewWillAppear() {
        self.setupNotificationBadgeRefreshTimer()
        self.registerForNotifications()
    }
    
    override func viewDidAppear() {
        self.displayIconsInDockScrollView(nil)
    }
    
    private func registerForNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(displayIconsInDockScrollView(_:)),
                                                          name: NSWorkspace.willLaunchApplicationNotification,
                                                          object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(displayIconsInDockScrollView(_:)),
                                                          name: NSWorkspace.didLaunchApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(displayIconsInDockScrollView(_:)),
                                                          name: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(displayIconsInDockScrollView(_:)),
                                                          name: NSWorkspace.didDeactivateApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(displayIconsInDockScrollView(_:)),
                                                          name: NSWorkspace.didTerminateApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.setupNotificationBadgeRefreshTimer),
                                                          name: .didChangeNotificationBadgeRefreshRate,
                                                          object: nil)
    }
}

extension DockWidget {
    
    @objc fileprivate func displayIconsInDockScrollView(_ notification: NSNotification?) {
        
        /// Remove all olds item views
        self.dockContentView.subviews.forEach({ subview in
            subview.removeFromSuperview()
        })
        
        /// Iterate on dockItems
       self.items.enumerated().forEach({ index, dockItem in
            
            /// Try get item view from cache
            let itemView: PockItemView!
            if let cachedItemView = self.itemViews[dockItem.bundleIdentifier] {
                itemView = cachedItemView
                itemView.reloadUI()
            }else {
                itemView = PockItemView(frame: .zero)
                itemView.dockItem = dockItem
                self.itemViews[dockItem.bundleIdentifier] = itemView
            }
        
            /// Check for bouncing animation
            if let runningApplication = PockUtilities.getRunningApplication(from: notification) {
                if runningApplication.bundleIdentifier == dockItem.bundleIdentifier {
                    if notification?.name == NSWorkspace.willLaunchApplicationNotification {
                        itemView.startBounceAnimation()
                    }else if notification?.name == NSWorkspace.didActivateApplicationNotification {
                        itemView.stopBounceAnimation()
                    }
                }
            }
            
            /// Add dockView to scroll view
            self.dockContentView.addSubview(itemView)
            
            /// Change x position
            itemView.frame.origin.x = 50 * CGFloat(index)
            
        })
        
        /// Update dockContentView content size
        self.dockContentView.frame.size.width = 50 * CGFloat(self.items.count)
        self.dockContentView.frame.size.height = self.dockScrollView.frame.height
        
        /// Set dockContentView as scrollView's documentView
        if self.dockScrollView.documentView != self.dockContentView {
            self.dockScrollView.documentView = self.dockContentView
        }
    }
    
    /// Reload badges and running dot
    @objc private func reloadBadgesAndRunningDot() {
        /// Iterate on dock content view
        for itemView in itemViews.values {
            /// Update UI
            itemView.reloadUI()
        }
    }
    
}

extension DockWidget {
    
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
    
}
