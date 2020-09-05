//
//  DestinationView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/09/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import AppKit

internal class DestinationView: RoundedRectView {

    // MARK: Data
    internal var completion: ((URL) -> Void)?
    
    // MARK: Core
    private let defaultColor      = NSColor.quaternaryLabelColor
    private let draggingColor     = NSColor.systemBlue.withAlphaComponent(0.3)
    private let allowedExtensions = ["pock"]

    // MARK: Initialisers
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.color = defaultColor
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }

    // MARK: Overrides
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(for: sender) == true {
            self.color = draggingColor
            return .copy
        } else {
            return NSDragOperation()
        }
    }

    fileprivate func checkExtension(for draggingInfo: NSDraggingInfo) -> Bool {
        guard let list = draggingInfo.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray, let path = list.firstObject as? String else {
            return false
        }
        let draggedFileExtension = URL(fileURLWithPath: path).pathExtension
        return self.allowedExtensions.map({ $0.lowercased() }).contains(draggedFileExtension)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.color = defaultColor
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.color = defaultColor
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path       = pasteboard[0] as? String,
              let url        = URL(string: path) else {
                return false
        }
        completion?(url)
        return true
    }
}
