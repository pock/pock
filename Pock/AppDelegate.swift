//
//  AppDelegate.swift
//  Pock
//
//  Created by Pierluigi Galdi on 08/09/17.
//  Copyright © 2017 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import CoreGraphics
import Magnet
import SnapKit

/// Custom identifiers
@available(OSX 10.12.2, *)
extension NSTouchBarItem.Identifier {
    static let pockSystemIcon = NSTouchBarItem.Identifier("com.pigigaldi.pock.pockSystemIcon")
    static let dockScrollableView = NSTouchBarItem.Identifier("com.pigigaldi.pock.dockScrollableView")
    static let escButton = NSTouchBarItem.Identifier("com.pigigaldi.pock.escButton")
}

/// Known identifiers
public let kFinderIdentifier: String = "com.apple.finder"

/// Public utitlities
public func executeWithDelay(delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: UInt64(delay * Double(NSEC_PER_SEC))), execute: closure)
}

@available(OSX 10.12.2, *)
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// UI
    fileprivate let dockScrollView: NSScrollView = NSScrollView(frame: .zero)
    fileprivate let dockContentView: NSView = NSView(frame: .zero)
    
    /// Touch Bar
    fileprivate var pockTouchBar: NSTouchBar?
    
    /// Dock icons scrubber
    public static var pockDockIconsScrubber: NSScrubber?
    
    /// Dock's list array
    fileprivate var dockItems: [PockItem] = []
    
    /// Status bar Pock icon
    fileprivate let pockStatusbarIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    /// Finish launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        /// Check for accessibility (needed for badges to work)
        self.checkAccessibility()
        
        /// Check for status bar icon
        if let button = pockStatusbarIcon.button {
            button.image = #imageLiteral(resourceName: "pock-inner-icon")
            button.image?.isTemplate = true
            /// Create menu
            let menu = NSMenu(title: "Menu")
            menu.addItem(withTitle: "Quit Pock.", action: #selector(NSApp.terminate(_:)), keyEquivalent: "")
            pockStatusbarIcon.menu = menu
        }
        
        /// Init touch bar
        self.initTouchBar()
        
        /// Initialize global hotkey.
        self.initializeHotKey()
        
        /// Load data
        self.loadData()
        
        /// Register for notification
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.loadData),
                                                          name: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(self.reloadBadgesAndRunningDot),
                                                          name: NSWindow.didUpdateNotification,
                                                          object: nil)
        
        /// Set Pock inactive
        NSApp.deactivate()
        
    }
    
    /// Will terminate
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    /// Check for accessibility
    @discardableResult
    private func checkAccessibility() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        return accessEnabled
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
        executeWithDelay(delay: 0.1, closure: {
            self.displayIconsInScrollView()
        })
    
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
    
        /// Remove all olds item views
        self.dockContentView.subviews.forEach({ subview in
            subview.removeFromSuperview()
        })
        
        /// Iterate on dockItems
        self.dockItems.enumerated().forEach({ index, dockItem in
        
            /// Get icon view
            let itemView = PockItemView()
            itemView.dockItem = dockItem
            
            /// Add dockView to scroll view
            self.dockContentView.addSubview(itemView)
            
            /// Change x position
            itemView.frame.origin.x = 50 * CGFloat(index)
        
        })
        
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
        NSTouchBar.presentSystemModalFunctionBar(self.touchBar(), systemTrayItemIdentifier: NSTouchBarItem.Identifier.pockSystemIcon.rawValue)
        
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
extension AppDelegate: NSTouchBarDelegate {
    
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
