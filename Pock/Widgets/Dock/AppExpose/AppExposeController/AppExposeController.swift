//
//  AppExposeController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 07/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class AppExposeController: PKTouchBarController {
    
    /// UI
    @IBOutlet private weak var appName:      NSTextField!
    @IBOutlet private weak var windowsCount: NSTextField!
    @IBOutlet private weak var scrubber:     NSScrubber!
    
    /// Core
    private var dockRepository: DockRepository!
    private var app: NSRunningApplication!
    private var elements: [AppExposeItem] = []
    
    deinit {
        if !isProd { print("[AppExposeController]: Deinit controller for app: \(app.localizedName ?? "Unknown")") }
    }
    
    override func present() {
        guard app != nil else { return }
        super.present()
        self.setAppName(name: app.localizedName ?? "<missing name>")
    }
    
    override func didLoad() {
        scrubber?.register(AppExposeItemView.self, forItemIdentifier: Constants.kAppExposeItemView)
    }
    
    @IBAction func willClose(_ button: NSButton?) {
        AppDelegate.default.navController?.popToRootController()
    }
    
}


extension AppExposeController {
    public func set(elements: [AppExposeItem]) {
        self.elements = elements
        self.windowsCount.stringValue = "\(elements.count) windows"
        self.scrubber.reloadData()
    }
    public func set(app: NSRunningApplication) {
        self.app = app
    }
    private func setAppName(name: String?) {
        self.appName.stringValue = name ?? "Unknown".localized
    }
}

extension AppExposeController: NSScrubberDataSource {
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return elements.count
    }
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let item = elements[index]
        let icon = item.minimized ? app.icon : item.preview
        let scaling: NSImageScaling = item.minimized ? .scaleProportionallyUpOrDown : .scaleAxesIndependently
        let view = scrubber.makeItem(withIdentifier: Constants.kAppExposeItemView, owner: self) as! AppExposeItemView
        view.set(preview: icon, imageScaling: scaling)
        view.set(name: item.name)
        view.set(minimized: item.minimized)
        return view
    }
}

extension AppExposeController: NSScrubberFlowLayoutDelegate {
    func scrubber(_ scrubber: NSScrubber, layout: NSScrubberFlowLayout, sizeForItemAt itemIndex: Int) -> NSSize {
        return NSSize(width: 80, height: 30)
    }
}

extension AppExposeController: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        let item = elements[selectedIndex]
        PockDockHelper.sharedInstance()?.activate(item, in: app)
//        if item.minimized {
//            PockDockHelper.sharedInstance()?.activate(item, in: app)
//        }else if PockDockHelper.sharedInstance()?.windowIsFrontmost(item.wid, forApp: app) ?? false {
//            PockDockHelper.sharedInstance()?.minimizeWindowItem(item)
//        }
        willClose(nil)
    }
}
