//
//  WidgetsManagerListPane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import AppKit
import Preferences

fileprivate struct WidgetInfo {
    let path:    URL?
    let id:      String
    let name:    String
    let version: String
    let loaded:  Bool
}

internal class WidgetsManagerListPane: NSViewController, PreferencePane {

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
    private var widgets: [WidgetInfo] = []
    
    // MARK: Overrides
    override func viewWillAppear() {
        super.viewWillAppear()
        
        /// Clear UI
        widgets = []
        tableView.reloadData()
        updateStatusLabel()
        
        /// Fetch installed widgets
        fetchInstalledWidgets() { [weak self] widgets in
            self?.widgets = widgets
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
    
    /// Fetch installed widgets
    private func fetchInstalledWidgets(_ completion: @escaping ([WidgetInfo]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let paths = WidgetsDispatcher.default.installedWidgetsPaths
            let widgets = paths.map({ path in
                /// TODO: Fetch proper widget information (id, version, status, etc...)
                WidgetInfo(
                    path:    path,
                    id:      "dev.pock.weather",
                    name:    path.lastPathComponent,
                    version: "0.1",
                    loaded:  false
                )
            })
            completion(widgets)
        }
    }
    
}

extension WidgetsManagerListPane {

    /// Update status label
    private func updateStatusLabel() {
        guard tableView.selectedRow > -1 else {
            self.statusLabel.stringValue = "\(numberOfRows(in: tableView)) widgets installed"
            return
        }
        let widget = widgets[tableView.selectedRow]
        self.statusLabel.stringValue = widget.id
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
        let widget = widgets[row]
        
        /// Define cell identifier
        let cellText:  String?
        let cellImage: NSImage?
        
        /// Get proper cell identifier based on tableColumn
        switch tableColumn?.identifier {
        case CellIdentifiers.nameCellIdentifier:
            cellText  = widget.name
            cellImage = nil
            
        case CellIdentifiers.versionCellIdentifier:
            cellText  = widget.version
            cellImage = nil
            
        case CellIdentifiers.statusCellIdentifier:
            cellText  = nil
            cellImage = NSImage(named: widget.loaded ? NSImage.statusAvailableName : NSImage.statusUnavailableName)
            
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
