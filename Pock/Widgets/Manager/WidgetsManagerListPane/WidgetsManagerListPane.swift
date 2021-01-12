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
	@IBOutlet private weak var preferencesContainer: NSView!
	@IBOutlet private weak var preferencesStatusLabel: NSTextField!
    
    // MARK: Data
    private var widgets: [WidgetInfo] = []
    private var selectedWidget: WidgetInfo?
	private var selectedPreferences: PKWidgetPreference?
	
	override var preferredMinimumSize: NSSize {
		return NSSize(width: 650, height: 300)
	}
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.register(NSNib(nibNamed: "PKWidgetCellView", bundle: .main), forIdentifier: CellIdentifiers.widgetCell)
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
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.reloadData()
    }
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		loadWindowForPreferenceClass(nil)
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
			/// Fetch new versions first
			PockUpdater.default.fetchNewVersions { _ in
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
    }
    
    /// Open window for preference class
    private func loadWindowForPreferenceClass(_ clss: PKWidgetPreference.Type?) {
		self.selectedPreferences?.view.removeFromSuperview()
		self.selectedPreferences?.removeFromParent()
		self.selectedPreferences = nil
		self.preferencesStatusLabel.stringValue = "This widget has no preferences".localized
		if let clss = clss {
			self.selectedPreferences = clss.init(nibName: clss.nibName, bundle: Bundle(for: clss))
			if let controller = self.selectedPreferences {
				self.preferencesStatusLabel.stringValue = ""
				addChild(controller)
				preferencesContainer.addSubview(controller.view)
				controller.view.snp.makeConstraints {
					$0.edges.equalToSuperview()
				}
				view.setNeedsDisplay(view.visibleRect)
			}
		}
    }
	
	/// Update widget
	@IBAction private func updateSelectedWidget(_ sender: Any? = nil) {
		guard let widget = selectedWidget, let newVersion = newVersion(for: widget) else {
			return
		}
		do {
			self.updateButton.isEnabled = false
			self.updateButton.title = "Updating…".localized
			self.uninstallButton.isEnabled = false
			try PockHelper.default.openProcessControllerForWidget(configuration: .default(remoteURL: newVersion.link), {
				PockUpdater.default.fetchNewVersions(ignoreCache: true) { [weak self] _ in
					self?.reloadData(nil)
				}
			}, { success in
				PockUpdater.default.fetchNewVersions(ignoreCache: true) { [weak self] _ in
					self?.reloadData(nil)
				}
			})
		} catch {
			NSLog("[WidgetsManagerListPane]: Can't update widget. Reason: \(error.localizedDescription)")
		}
	}
    
    /// Uninstall widget
    @IBAction private func uninstallSelectedWidget(_ sender: Any? = nil) {
        guard let widget = selectedWidget else {
            return
        }
        do {
			self.updateButton.isEnabled = false
			self.uninstallButton.title = "Uninstalling…".localized
			self.uninstallButton.isEnabled = false
			try PockHelper.default.openProcessControllerForWidget(configuration: .default(process: .remove, widgetInfo: widget), {
				PockUpdater.default.fetchNewVersions(ignoreCache: true) { [weak self] _ in
					self?.reloadData(nil)
				}
			}, { success in
				PockUpdater.default.fetchNewVersions(ignoreCache: true) { [weak self] _ in
					self?.reloadData(nil)
				}
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
        guard let widget = selectedWidget else {
			self.updateButton.isEnabled = false
            self.uninstallButton.isEnabled = false
			self.updateButton.title = "Update".localized
			self.uninstallButton.title = "Uninstall".localized
			self.widgetNameLabel.stringValue = ""
			self.widgetAuthorLabel.stringValue = ""
			self.widgetVersionLabel.stringValue = ""
			self.widgetNameLabel.placeholderString = "Widget Name"
			self.widgetAuthorLabel.placeholderString = "Author"
			self.widgetVersionLabel.placeholderString = "Version"
			self.loadWindowForPreferenceClass(nil)
            return
        }
		self.updateButton.isEnabled = newVersion(for: widget) != nil
        self.uninstallButton.isEnabled = true
		self.widgetNameLabel.stringValue = widget.name
		self.widgetAuthorLabel.stringValue = widget.author
		self.widgetVersionLabel.stringValue = widget.version
		self.loadWindowForPreferenceClass(widget.preferenceClass as? PKWidgetPreference.Type)
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
	
	private func newVersion(for widget: WidgetInfo) -> Version? {
		guard let newVersion = PockUpdater.default.latestReleases?.widgets.first(where: { $0.key.lowercased() == widget.id.lowercased()
		})?.value else {
			return nil
		}
		return widget.version < newVersion.name ? newVersion : nil
	}
	
    /// View for cell in row
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        /// Check for cell
		guard let cell = tableView.makeView(withIdentifier: CellIdentifiers.widgetCell, owner: nil) as? PKWidgetCellView else {
            return nil
        }
        /// Get item
        let widget = widgets[row]
        /// Setup cell
		cell.status.image = NSImage(named: widget.loaded ? NSImage.statusAvailableName : NSImage.statusUnavailableName)
		cell.name.stringValue = widget.name
		cell.badge.isHidden = newVersion(for: widget) == nil
        /// Return
        return cell
    }
    
    /// Did select row
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.selectedWidget = tableView.selectedRow > -1 ? widgets[tableView.selectedRow] : nil
        self.updateUIElements()
    }
    
}
