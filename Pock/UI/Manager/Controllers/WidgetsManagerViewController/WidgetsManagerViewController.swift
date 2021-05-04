//
//  WidgetsManagerViewController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 30/04/21.
//

import Cocoa
import PockKit
import TinyConstraints

class WidgetsManagerViewController: NSViewController {
	
	// MARK: Cell Identifiers
	
	private enum CellIdentifiers {
		static let widgetCell: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("widgetCellIdentifier")
	}
	
    // MARK: UI Elements
	///
	/// Common UI elements
	@IBOutlet private weak var tableView: NSTableView!
	/// Selected widget's UI elements
	@IBOutlet private weak var widgetNameLabel: NSTextField!
	@IBOutlet private weak var widgetAuthorLabel: NSTextField!
	@IBOutlet private weak var widgetVersionLabel: NSTextField!
	@IBOutlet private weak var widgetUpdateButton: NSButton!
	@IBOutlet private weak var widgetUninstallButton: NSButton!
	@IBOutlet private weak var widgetUpdateStatusLabel: NSTextField!
	@IBOutlet private weak var widgetPreferencesContainer: NSView!
	@IBOutlet private weak var widgetPreferencesStatusLabel: NSTextField!
	
	// MARK: Data
	
	private var widgets: [PKWidgetInfo] {
		return WidgetsLoader.installedWidgets.sorted(by: { $0.name < $1.name })
	}
	private var selectedWidget: PKWidgetInfo? {
		didSet {
			updateUIElementsForSelectedWidget()
			updatePreferencesContainerForSelectedPreferences()
		}
	}
	private var selectedPreferences: PKWidgetPreference?
	
	/// Set of disabled widget's `bundleIdentifier` to avoid user selection
	private var disabledWidgets: Set<String> = []
	
	// MARK: Overrides
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.register(NSNib(nibNamed: "PKWidgetCellView", bundle: .main), forIdentifier: CellIdentifiers.widgetCell)
		self.selectedWidget = widgets.first
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		NSApp.activate(ignoringOtherApps: true)
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		NSApp.deactivate()
	}
	
	deinit {
		selectedWidget = nil
		Roger.debug("[WidgetsManager][List] - deinit")
	}
	
}

// MARK: Methods

extension WidgetsManagerViewController {
	
	private func updatePreferredContentSize() {
		let frame = widgetPreferencesContainer.convert(widgetPreferencesContainer.visibleRect, to: view)
		self.preferredContentSize = NSSize(
			width: frame.origin.x + frame.size.width,
			height: frame.origin.y + frame.size.height
		)
		self.view.layout()
	}
	
	private func updateUIElementsForSelectedWidget() {
		guard let widget = selectedWidget else {
			widgetNameLabel.stringValue = "widgets-manager.list.select-widget".localized
			widgetAuthorLabel.stringValue = "--"
			widgetVersionLabel.stringValue = "--"
			widgetUninstallButton.isEnabled = false
			widgetUpdateButton.isEnabled = false
			widgetUpdateStatusLabel.isHidden = true
			return
		}
		widgetNameLabel.stringValue = widget.name
		widgetAuthorLabel.stringValue = widget.author
		widgetVersionLabel.stringValue = widget.version
		widgetUninstallButton.isEnabled = true
		// TODO: Add check for `update` UI elements (button, label)
		widgetUpdateButton.isEnabled = false
		widgetUpdateStatusLabel.isHidden = true
	}
	
	private func updatePreferencesContainerForSelectedPreferences() {
		guard let widget = selectedWidget, let clss = widget.preferencesClass as? PKWidgetPreference.Type else {
			unloadPreferencesContainerWithTitle("widgets-manager.list.no-preferences".localized)
			selectedPreferences = nil
			return
		}
		if disabledWidgets.contains(where: { $0 == widget.bundleIdentifier }) {
			unloadPreferencesContainerWithTitle("widgets-manager.list.did-update".localized)
		} else {
			unloadPreferencesContainerWithTitle("widgets-manager.loading-preferences".localized)
			selectedPreferences = clss.init(nibName: clss.nibName, bundle: Bundle(for: clss))
			loadPreferencesContainerForSelectedPreferences()
		}
	}
	
	private func loadPreferencesContainerForSelectedPreferences() {
		guard let preferences = selectedPreferences else {
			return
		}
		widgetPreferencesStatusLabel.stringValue = ""
		widgetPreferencesStatusLabel.isHidden = true
		addChild(preferences)
		widgetPreferencesContainer.addSubview(preferences.view)
		preferences.view.edgesToSuperview()
		async { [weak self] in
			self?.updatePreferredContentSize()
		}
	}
	
	private func unloadPreferencesContainerWithTitle(_ title: String) {
		selectedPreferences?.view.removeFromSuperview()
		selectedPreferences?.removeFromParent()
		selectedPreferences = nil
		widgetPreferencesStatusLabel.stringValue = title
		widgetPreferencesStatusLabel.isHidden = false
	}
	
	internal func presentWidgetInstallPanel() {
		let controller = WidgetsInstallViewController()
		presentAsSheet(controller)
	}
	
}

// MARK: Table - Data Source

extension WidgetsManagerViewController: NSTableViewDataSource {
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return widgets.count
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 44
	}
	
	func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
		return 220
	}
	
}

// MARK: Table - Delegate

extension WidgetsManagerViewController: NSTableViewDelegate {
	
	/// View for cell in row
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		/// Check for cell
		guard row < widgets.count, let cell = tableView.makeView(withIdentifier: CellIdentifiers.widgetCell, owner: nil) as? PKWidgetCellView else {
			return nil
		}
		/// Get item
		let widget = widgets[row]
		let disabled = disabledWidgets.contains(where: { $0 == widget.bundleIdentifier })
		/// Setup cell
		cell.status.image = NSImage(named: widget.loaded ? NSImage.statusAvailableName : NSImage.statusUnavailableName)
		cell.name.stringValue = widget.name
		cell.name.alphaValue  = disabled ? 0.475 : 1
		cell.badge.isHidden = disabled // TODO: || PockUpdater.default.newVersion(for: widget) == nil
		/// Return
		return cell
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		self.selectedWidget = tableView.selectedRow > -1 ? widgets[tableView.selectedRow] : nil
	}
	
}
