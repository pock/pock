//
//  AppDelegate.swift
//  Pock
//
//  Created by Pierluigi Galdi on 08/09/17.
//  Copyright © 2017 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Magnet
import SnapKit

/// Custom identifiers
extension NSTouchBarItemIdentifier {
    static let pockSystemIcon = NSTouchBarItemIdentifier("com.pigigaldi.pock.systemIcon")
    static let dockScrollableView = NSTouchBarItemIdentifier("com.pigigaldi.pock.dockScrollableView")
}

@available(OSX 10.12.2, *)
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// Touch Bar
    fileprivate var pockTouchBar: NSTouchBar?
    
    /// Dock icons scrubber
    public static var pockDockIconsScrubber: NSScrubber?
    
    /// Dock's list array
    fileprivate var dockItems: [DockItem] = []
    
    /// Status bar Pock icon
    fileprivate let pockStatusbarIcon = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    
    /// Finish launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
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
        NSWorkspace.shared().notificationCenter.addObserver(self,
                                                            selector: #selector(self.loadData),
                                                            name: NSNotification.Name.NSWorkspaceDidActivateApplication,
                                                            object: nil)
        
        /// Set Pock inactive
        NSApp.deactivate()
        
    }
    
    /// Will terminate
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
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
        
        /// Set running indicator
        self.dockItems.forEach({ dockItem in
            
            /// Set running indicator
            dockItem.isRunning = PockUtilities.runningAppsIdentifiers.contains(dockItem.bundleIdentifier)
            
            /// Set if is frontmostApplication
            dockItem.isFrontmostApplication = (dockItem.bundleIdentifier == PockUtilities.frontmostApplicationIdentifier)
            
            /// If Finder, insert as first
            if dockItem.bundleIdentifier == "com.apple.finder" {
                guard let index = self.dockItems.index(of: dockItem) else { return }
                let finderItem = self.dockItems.remove(at: index)
                self.dockItems.insert(finderItem, at: 0)
            }
            
        })
        
        /// Reload scrubber, if any
        AppDelegate.pockDockIconsScrubber?.reloadData()
    
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
        NSTouchBar.presentSystemModalFunctionBar(self.touchBar(), systemTrayItemIdentifier: NSTouchBarItemIdentifier.pockSystemIcon.rawValue)
    }
    
    /// Add global hotkey for setting Pock as top-most-application
    private func initializeHotKey() {
        
        /// Create HotKey
        if let keyCombo = KeyCombo(keyCode: 35, cocoaModifiers: [.command, .option]) {
            let hotKey = HotKey(identifier: "CommandP", keyCombo: keyCombo, target: self, action: #selector(self.addPockItemToControlStrip))
            let _ = HotKeyCenter.shared.register(with: hotKey)
        }
        
    }
    
    @objc fileprivate func addPockItemToControlStrip() {
        self.presentPock()
    }
    
}

@available(OSX 10.12.2, *)
extension AppDelegate: NSScrubberDelegate, NSScrubberDataSource {
    
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return self.dockItems.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        /// Return item customized for dock icon.
        let itemView = scrubber.makeItem(withIdentifier: "DockIconScrubberItem", owner: nil) as! PockItemView
        
        /// Get item
        let item = self.dockItems[index]
        
        /// Create icon view
        itemView.dockItem = item
        
        /// Check if is frontmostApplication
        if item.isFrontmostApplication {
            
            /// Set as selected
            scrubber.selectedIndex = index
            
        }

        /// Return item view
        return itemView
    }
    
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt index: Int) {
        
        /// Get item
        let item = self.dockItems[index]
        
        /// Launch application
        PockUtilities.launch(bundleIdentifier: item.bundleIdentifier, completion: { _ in })
    
    }

}

@available(OSX 10.12.2, *)
extension AppDelegate: NSTouchBarDelegate {
    
    func touchBar() -> NSTouchBar? {
        guard self.pockTouchBar == nil else { return self.pockTouchBar }
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.dockScrollableView]
        self.pockTouchBar = touchBar
        return self.pockTouchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        switch identifier {
        case NSTouchBarItemIdentifier.dockScrollableView:
            
            /// Return scrollable item
            let item = NSCustomTouchBarItem(identifier: identifier)
            
            guard AppDelegate.pockDockIconsScrubber == nil else {
                
                /// Reload data
                AppDelegate.pockDockIconsScrubber?.reloadData()
                item.view = AppDelegate.pockDockIconsScrubber!
                
                /// Stop here
                return item
                
            }
            
            AppDelegate.pockDockIconsScrubber = NSScrubber()
            AppDelegate.pockDockIconsScrubber?.scrubberLayout = NSScrubberFlowLayout()
            AppDelegate.pockDockIconsScrubber?.register(PockItemView.self, forItemIdentifier: "DockIconScrubberItem")
            AppDelegate.pockDockIconsScrubber?.mode = .free
            AppDelegate.pockDockIconsScrubber?.showsAdditionalContentIndicators = true
            AppDelegate.pockDockIconsScrubber?.selectionBackgroundStyle = .roundedBackground
            AppDelegate.pockDockIconsScrubber?.delegate = self
            AppDelegate.pockDockIconsScrubber?.dataSource = self
            item.view = AppDelegate.pockDockIconsScrubber!
            return item
            
        case NSTouchBarItemIdentifier.pockSystemIcon:
            
            /// Return Pock system item
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSButton(image: #imageLiteral(resourceName: "pock-inner-icon"), target: self, action: #selector(self.addPockItemToControlStrip))
            return item
            
        default:
            return nil
        }
        
    }
    
}
