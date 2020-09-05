//
//  WidgetsManagerListPane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import AppKit
import Preferences

internal class WidgetsManagerListPane: NSViewController, PreferencePane {

    // MARK: Preferenceable
    var preferencePaneIdentifier: Preferences.PaneIdentifier = Preferences.PaneIdentifier.widgets_manager_list
    let preferencePaneTitle:      String     = "Widgets".localized
    var toolbarItemIcon:          NSImage    = NSImage(named: "WidgetsManagerList")!
    
    // MARK: Cell Identifiers
    private enum CellIdentifiers {
        static let nameCellIdentifier:    NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("nameCellIdentifier")
        static let authorCellIdentifier:  NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("authorCellIdentifier")
        static let versionCellIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("versionCellIdentifier")
        static let statusCellIdentifier:  NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("statusCellIdentifier")
    }
    
    // MARK: UI Elements
    @IBOutlet private weak var tableView:         NSTableView!
    @IBOutlet private weak var statusLabel:       NSTextField!
    @IBOutlet private weak var preferencesButton: NSButton!
    @IBOutlet private weak var uninstallButton:   NSButton!
    
    // MARK: Menu
    private lazy var rightClickMenu: NSMenu = {
        let menu = NSMenu(title: "Widget Options".localized)
        menu.delegate = self
        return menu
    }()
    
    // MARK: Data
    private var widgets: [WidgetInfo] = []
    private var selectedWidget: WidgetInfo?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadData(_:)),
                                               name: .didLoadInstalledWidgets,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadData(_:)),
                                               name: .didInstallWidget,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadData(_:)),
                                               name: .didUninstallWidget,
                                               object: nil)
        self.tableView.menu = rightClickMenu
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: Methods

extension WidgetsManagerListPane {
    
    /// Reload data
    @IBAction private func reloadData(_ sender: Any? = nil) {
        /// Clear UI
        widgets = []
        selectedWidget = nil
        async { [weak self] in
            self?.tableView.reloadData()
            self?.updateUIElements()
            /// Fetch installed widgets
            self?.fetchInstalledWidgets() { [weak self] widgets in
                self?.widgets = widgets
                /// Update UI on main thread
                async { [weak self] in
                    self?.tableView.reloadData()
                    self?.updateUIElements()
                }
            }
        }
    }
    
    /// Open preferences for selected widget
    @IBAction private func openPreferencePaneForWidget(_ sender: Any? = nil) {
        guard let widget = selectedWidget, let clss = widget.preferenceClass as? PKWidgetPreference.Type else {
            return
        }
        openWindowForPreferenceClass(clss, title: widget.name)
    }
    
    /// Open window for preference class
    private func openWindowForPreferenceClass(_ clss: PKWidgetPreference.Type, title: String? = nil) {
        let controller = clss.init(nibName: clss.nibName, bundle: Bundle(for: clss))
        controller.title = controller.title ?? title ?? clss.nibName
        self.presentAsModalWindow(controller)
    }
    
    /// Uninstall widget
    @IBAction private func uninstallSelectedWidget(_ sender: Any? = nil) {
        guard let widget = selectedWidget else {
            return
        }
        do {
            try PockHelper.default.openProcessControllerForWidget(configuration: .default(process: .remove, widgetInfo: widget))
        } catch {
            print("[WidgetsManagerListPane]: Can't process widget. Reason: \(error.localizedDescription)")
        }
    }
    
    /// Fetch installed widgets
    private func fetchInstalledWidgets(_ completion: @escaping ([WidgetInfo]) -> Void) {
        background {
            let widgets = WidgetsDispatcher.default.installedWidgets
            completion(widgets)
        }
    }
    
}

extension WidgetsManagerListPane {

    /// Update status label
    private func updateUIElements() {
        guard let widget = selectedWidget else {
            self.preferencesButton.isEnabled = false
            self.uninstallButton.isEnabled   = false
            let count = widgets.count
            self.statusLabel.stringValue   = "\(count) widget\(count == 1 ? "" : "s") installed"
            return
        }
        self.statusLabel.stringValue     = "\(widget.name) (\(widget.version)) selected"
        self.preferencesButton.isEnabled = widget.hasPreferences
        self.uninstallButton.isEnabled   = true
    }

}

// MARK: Menu Delegate
extension WidgetsManagerListPane: NSMenuDelegate {
    
    /// Adjust menu elements
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let row = tableView.clickedRow
        if row > -1 && row < widgets.count {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            if selectedWidget?.preferenceClass as? PKWidgetPreference.Type != nil {
                menu.addItem(withTitle: "Preferences…".localized, action: #selector(openPreferencePaneForWidget(_:)), keyEquivalent: ",")
            }
        }
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
            
        case CellIdentifiers.authorCellIdentifier:
            cellText  = widget.author
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
        self.selectedWidget = tableView.selectedRow > -1 ? widgets[tableView.selectedRow] : nil
        self.updateUIElements()
    }
    
}
