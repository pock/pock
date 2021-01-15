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
        static let widgetCell: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("widgetCellIdentifier")
    }
    
    // MARK: UI Elements
    @IBOutlet private weak var tableView:          NSTableView!
	@IBOutlet private weak var widgetNameLabel:    NSTextField!
	@IBOutlet private weak var widgetAuthorLabel:  NSTextField!
	@IBOutlet private weak var widgetVersionLabel: NSTextField!
	@IBOutlet private weak var updateButton:	   NSButton!
    @IBOutlet private weak var uninstallButton:    NSButton!
	@IBOutlet private weak var unableToUpdateLabel:    NSTextField!
	@IBOutlet private weak var preferencesContainer:   NSView!
	@IBOutlet private weak var preferencesStatusLabel: NSTextField!
    
    // MARK: Data
    private var widgets: [WidgetInfo] = []
	private var disabledWidgets: Set<String> = []
	private var selectedWidget: WidgetInfo? {
		didSet {
			selectedWidgetNewVersion = PockUpdater.default.newVersion(for: selectedWidget)
		}
	}
	private var selectedWidgetNewVersion: VersionModel?
	private var selectedPreferences: PKWidgetPreference?
	
	private var updateAlertController: UpdateAlertController?
	
	override var preferredMinimumSize: NSSize {
		return NSSize(width: 650, height: 300)
	}
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.register(NSNib(nibNamed: "PKWidgetCellView", bundle: .main), forIdentifier: CellIdentifiers.widgetCell)
		self.updateUIElements()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.reloadData()
    }
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		/// Clear UI
		widgets = []
		selectedWidget = nil
		async { [weak self] in
			self?.unloadWindowForPreference(title: "This widget has no preferences".localized)
			self?.tableView.reloadData()
			self?.updateUIElements()
		}
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
			self?.unloadWindowForPreference(title: "This widget has no preferences".localized)
            self?.tableView.reloadData()
            self?.updateUIElements()
			/// Fetch new versions first
			PockUpdater.default.fetchNewVersions(ignoreCache: true) { _ in
				/// Fetch installed widgets
				self?.fetchInstalledWidgets() { [weak self] widgets in
					self?.widgets = widgets
					if !widgets.contains(where: { $0.id == self?.selectedWidget?.id }) {
						self?.selectedWidget = nil
					}
					/// Update UI on main thread
					async { [weak self] in
						self?.tableView.reloadData()
						self?.updateUIElements()
					}
				}
			}
        }
    }
    
	private func updatePreferredContentSize() {
		let frame = preferencesContainer.convert(preferencesContainer.visibleRect, to: view)
		self.preferredContentSize = NSSize(
			width: frame.origin.x + frame.size.width,
			height: frame.origin.y + frame.size.height
		)
		self.view.layout()
	}
	
    /// Open window for preference class
	private func loadPreferencesWindow(for widget: WidgetInfo?) {
		self.unloadWindowForPreference(title: "This widget has no preferences".localized)
		if let widget = widget, let clss = widget.preferenceClass as? PKWidgetPreference.Type {
			self.selectedPreferences = clss.init(nibName: clss.nibName, bundle: Bundle(for: clss))
			if let controller = self.selectedPreferences {
				self.preferencesStatusLabel.stringValue = ""
				self.preferencesStatusLabel.isHidden = true
				addChild(controller)
				preferencesContainer.addSubview(controller.view)
				controller.view.snp.makeConstraints {
					$0.edges.equalToSuperview()
				}
				async { [weak self] in
					self?.updatePreferredContentSize()
				}
			}
		}
    }
	private func unloadWindowForPreference(title: String?) {
		self.selectedPreferences?.view.removeFromSuperview()
		self.selectedPreferences?.removeFromParent()
		self.selectedPreferences = nil
		self.preferencesStatusLabel.stringValue = title ?? "\"Houston, we had a problem here\"".localized
		self.preferencesStatusLabel.isHidden = false
	}
	
	/// Update widget
	@IBAction private func updateSelectedWidget(_ sender: Any? = nil) {
		guard let widget = selectedWidget, let newVersion = selectedWidgetNewVersion?.version, let index = widgets.firstIndex(where: { $0.id == widget.id }) else {
			return
		}
		do {
			self.disabledWidgets.insert(widget.id)
			self.tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
			self.unloadWindowForPreference(title: "\(widget.name) Widget " + "will be updated".localized)
			self.updateButton.isEnabled = false
			self.updateButton.title = "Updating…".localized
			self.uninstallButton.isEnabled = false
			try PockHelper.default.openProcessControllerForWidget(configuration: .default(remoteURL: newVersion.link, process: .update), { [weak self, index] in
				self?.disabledWidgets.remove(widget.id)
				self?.tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
				self?.loadPreferencesWindow(for: self?.selectedWidget)
				self?.updateUIElements()
			}, { [weak self] _ in
				self?.unloadWindowForPreference(title: "Reload Pock to refresh widgets preferences".localized)
				self?.tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
				self?.updateUIElements()
			})
		} catch {
			NSLog("[WidgetsManagerListPane]: Can't update widget. Reason: \(error.localizedDescription)")
		}
	}
    
    /// Uninstall widget
    @IBAction private func uninstallSelectedWidget(_ sender: Any? = nil) {
		guard let widget = selectedWidget, let index = widgets.firstIndex(where: { $0.id == widget.id }) else {
            return
        }
        do {
			self.disabledWidgets.insert(widget.id)
			self.tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
			self.unloadWindowForPreference(title: "\(widget.name) Widget " + "will be removed".localized)
			self.updateButton.isEnabled = false
			self.uninstallButton.title = "Uninstalling…".localized
			self.uninstallButton.isEnabled = false
			try PockHelper.default.openProcessControllerForWidget(configuration: .default(process: .remove, widgetInfo: widget), { [weak self, index] in
				self?.disabledWidgets.remove(widget.id)
				self?.tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
				self?.loadPreferencesWindow(for: self?.selectedWidget)
				self?.updateUIElements()
			}, { [weak self] _ in
				self?.disabledWidgets.remove(widget.id)
				self?.widgets.remove(at: index)
				self?.tableView.removeRows(at: IndexSet(integer: index), withAnimation: .slideLeft)
				self?.loadPreferencesWindow(for: nil)
				self?.updateUIElements()
			})
        } catch {
            NSLog("[WidgetsManagerListPane]: Can't process widget. Reason: \(error.localizedDescription)")
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
		self.updateButton.isHighlighted = true
		self.updateButton.title = "Update".localized
		self.uninstallButton.title = "Uninstall".localized
		self.widgetNameLabel.placeholderString = "Widget Name".localized
		self.widgetAuthorLabel.placeholderString = "Author".localized
		self.widgetVersionLabel.placeholderString = "Version".localized
        guard let widget = selectedWidget else {
			self.updateButton.isEnabled = false
            self.uninstallButton.isEnabled = false
			self.widgetNameLabel.stringValue = ""
			self.widgetAuthorLabel.stringValue = ""
			self.widgetVersionLabel.stringValue = ""
			self.unableToUpdateLabel.isHidden = true
			self.loadPreferencesWindow(for: nil)
            return
        }
		let disabled = disabledWidgets.contains(where: { $0 == widget.id })
		self.updateButton.isEnabled = disabled == false && selectedWidgetNewVersion?.version != nil
        self.uninstallButton.isEnabled = disabled == false
		self.widgetNameLabel.stringValue = widget.name
		self.widgetAuthorLabel.stringValue = widget.author
		self.widgetVersionLabel.stringValue = widget.version + widget.build
		self.unableToUpdateLabel.stringValue = selectedWidgetNewVersion?.error ?? ""
		self.unableToUpdateLabel.isHidden = selectedWidgetNewVersion?.error == nil
    }
	
	private func showUpdateAlert(for widget: WidgetInfo, version: Version?) {
		guard let version = version,
			  let controller = UpdateAlertController(
				newVersion: version,
				fromVersion: widget.version + widget.build,
				packageName: "\(widget.name) Widget",
				updateHandle: { [weak self] in
					self?.updateSelectedWidget()
				}
			  ) else {
			return
		}
		self.presentAsSheet(controller)
	}

}

// MARK: Table - Data Source
extension WidgetsManagerListPane: NSTableViewDataSource {
    
    /// Number of rows
    func numberOfRows(in tableView: NSTableView) -> Int {
        return widgets.count
    }
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 42
	}
	
	func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
		return 220
	}
    
}

// MARK: Delegate
extension WidgetsManagerListPane: NSTableViewDelegate {
	
    /// View for cell in row
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        /// Check for cell
		guard widgets.count > row, let cell = tableView.makeView(withIdentifier: CellIdentifiers.widgetCell, owner: nil) as? PKWidgetCellView else {
            return nil
        }
        /// Get item
        let widget   = widgets[row]
		let disabled = disabledWidgets.contains(where: { $0 == widget.id })
        /// Setup cell
		cell.status.image 	  = NSImage(named: widget.loaded ? NSImage.statusAvailableName : NSImage.statusUnavailableName)
		cell.name.stringValue = widget.name
		cell.name.alphaValue  = disabled ? 0.475 : 1
		cell.badge.isHidden   = disabled || PockUpdater.default.newVersion(for: widget) == nil
        /// Return
        return cell
    }
    
    /// Did select row
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.selectedWidget = tableView.selectedRow > -1 ? widgets[tableView.selectedRow] : nil
		guard let selectedWidget = selectedWidget else {
			return
		}
        self.updateUIElements()
		if disabledWidgets.contains(where: { $0 == selectedWidget.id }) == false {
			self.loadPreferencesWindow(for: selectedWidget)
			self.showUpdateAlert(for: selectedWidget, version: selectedWidgetNewVersion?.version)
		}else {
			self.unloadWindowForPreference(title: "Reload Pock to refresh widgets preferences".localized)
		}
    }
    
}
