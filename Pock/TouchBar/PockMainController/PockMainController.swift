//
//  PockMainController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 21/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation

/// Custom identifiers
extension NSTouchBar.CustomizationIdentifier {
    static let pockTouchBar = "PockTouchBar"
}
extension NSTouchBarItem.Identifier {
    static let pockSystemIcon = NSTouchBarItem.Identifier("Pock")
    static let dockView       = NSTouchBarItem.Identifier("Dock")
    static let escButton      = NSTouchBarItem.Identifier("Esc")
    static let controlCenter  = NSTouchBarItem.Identifier("ControlCenter")
    static let nowPlaying     = NSTouchBarItem.Identifier("NowPlaying")
    static let status         = NSTouchBarItem.Identifier("Status")
}

class PockMainController: PockTouchBarController {
    
    /// Core
    private var loadedWidgets: [NSTouchBarItem.Identifier: PockWidget] = [:]
    
    override var systemTrayItem: NSCustomTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: .pockSystemIcon)
        item.view = NSButton(image: #imageLiteral(resourceName: "pock-inner-icon"), target: self, action: #selector(present))
        return item
    }
    override var systemTrayItemIdentifier: NSTouchBarItem.Identifier? { return .pockSystemIcon }
    
    required init() {
        super.init()
        self.showControlStripIcon()
    }
    
    deinit {
        self.loadedWidgets.removeAll()
        if !isProd { print("[PockMainController]: Deinit Pock main controller") }
    }
    
    private func loadPluginsFromFilesystem(completion: ([PockWidget]) -> Void) {
        self.loadedWidgets.removeAll()
        
        let path = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Pock"
        let widgetsPath = path + "/Widgets"
        var directoryExists: ObjCBool = false
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            try? FileManager.default.createDirectory(atPath: widgetsPath, withIntermediateDirectories: false, attributes: nil)
        }
        FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
        FileManager.default.fileExists(atPath: widgetsPath, isDirectory: &directoryExists)
        guard directoryExists.boolValue else {
            completion([])
            return
        }
        let enumerator = FileManager.default.enumerator(atPath: widgetsPath)
        let widgetBundles = (enumerator?.allObjects as? [String] ?? []).filter{ $0.contains(".pock") && !$0.contains("/") }
        for widgetBundle in widgetBundles {
            /// load bundle
            let bundlePath = "\(widgetsPath)/\(widgetBundle)"
            if let bundle = Bundle(path: bundlePath), bundle.load() {
                if let clss = bundle.principalClass as? PockWidget.Type {
                    let plugin = clss.init()
                    self.loadedWidgets[plugin.identifier] = plugin
                }
            }
        }
        completion(Array(loadedWidgets.values))
    }
    
    override func awakeFromNib() {
        self.loadPluginsFromFilesystem(completion: { widgets in
            self.touchBar?.customizationIdentifier              = .pockTouchBar
            self.touchBar?.defaultItemIdentifiers               = [.escButton, .dockView]
            self.touchBar?.customizationAllowedItemIdentifiers  = [.escButton, .dockView, .controlCenter, .nowPlaying, .status]
            
            let customizableIds: [NSTouchBarItem.Identifier] = widgets.map({ $0.identifier })
            self.touchBar?.customizationAllowedItemIdentifiers.append(contentsOf: customizableIds)
            
            super.awakeFromNib()
        })
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        var widget: PockWidget?
        switch identifier {
        /// Esc button
        case .escButton:
            widget = EscWidget()
        /// Dock widget
        case .dockView:
            widget = DockWidget()
        /// ControlCenter widget
        case .controlCenter:
            widget = ControlCenterWidget()
        /// NowPlaying widget
        case .nowPlaying:
            widget = NowPlayingWidget()
        /// Status widget
        case .status:
            widget = StatusWidget()
        default:
            widget = loadedWidgets[identifier]
        }
        guard widget != nil else { return nil }
        return PockWidgetTouchBarItem(widget: widget!)
    }
    
}
