//
//  WidgetsManagerListPane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import AppKit
import Preferences

class WidgetsManagerListPane: NSViewController, PreferencePane {

    // MARK: Preferenceable
    var preferencePaneIdentifier: Identifier = Identifier.widgets_manager_list
    let preferencePaneTitle:      String     = "Widgets".localized
    var toolbarItemIcon:          NSImage    = NSImage(named: "WidgetsManagerList")!
    
    // MARK: Cell Identifiers
    private enum CellIdentifiers {
        static let nameCellIdentifier:    NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nameCellIdentifier")
        static let versionCellIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "versionCellIdentifier")
        static let statusCellIdentifier:  NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "statusCellIdentifier")
    }
    
    // MARK: UI Elements
    @IBOutlet private weak var tableView:   NSTableView!
    @IBOutlet private weak var statusLabel: NSTextField!
    
    // MARK: Data
    private var widgets: [Int] = []
    
    // MARK: Overrides
    override func viewWillAppear() {
        super.viewWillAppear()
        /// Clear UI
        widgets = []
        tableView.reloadData()
        updateStatusLabel()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) { [weak self] in
            /// TODO: Fetch installed widgets
            self?.widgets = [1, 2, 3, 4, 5]
            /// Update UI on main thread
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.updateStatusLabel()
            }
        }
    }
    
}

// MARK: Methods
extension WidgetsManagerListPane {
    /// Update status label
    private func updateStatusLabel() {
        guard tableView.selectedRow > -1 else {
            self.statusLabel.stringValue = "\(numberOfRows(in: tableView)) widgets installed"
            return
        }
        let item = widgets[tableView.selectedRow]
        self.statusLabel.stringValue = "~/Library/Application Support/Pock/Widgets/Widget \(item).pock"
    }
}

// MARK: Data Source
extension WidgetsManagerListPane: NSTableViewDataSource {
    /// Number of rows
    func numberOfRows(in tableView: NSTableView) -> Int {
        return widgets.count
    }
}

// MARK: Delegate
extension WidgetsManagerListPane: NSTableViewDelegate {
    /// View for cell in row
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        /// Check for cell
        guard let id = tableColumn?.identifier, let cell = tableView.makeView(withIdentifier: id, owner: nil) as? NSTableCellView else {
            return nil
        }
        /// Get item
        let item = widgets[row]
        /// Define cell identifier
        let cellText:       String?
        let cellImage:      NSImage?
        /// Get proper cell identifier based on tableColumn
        switch tableColumn?.identifier {
        case CellIdentifiers.nameCellIdentifier:
            cellText       = "Widget \(item)"
            cellImage      = nil
            
        case CellIdentifiers.versionCellIdentifier:
            cellText       = "1.0.\(item)"
            cellImage      = nil
            
        case CellIdentifiers.statusCellIdentifier:
            cellText       = nil
            cellImage      = NSImage(named: NSImage.statusAvailableName)
            
        default:
            return nil
        }
        /// Setup cell
        cell.textField?.stringValue = cellText ?? ""
        cell.imageView?.image       = cellImage
        /// Return
        return cell
    }
    
    /// Did select row
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.updateStatusLabel()
    }
}
