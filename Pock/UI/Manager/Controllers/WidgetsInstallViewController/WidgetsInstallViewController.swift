//
//  WidgetsInstallViewController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/05/21.
//

import Cocoa

class WidgetsInstallViewController: NSViewController {

    // MARK: UI Elements
	
	@IBOutlet private weak var iconView: NSImageView!
	@IBOutlet private weak var titleLabel: NSTextField!
	@IBOutlet private weak var bodyLabel: NSTextField!
	@IBOutlet private weak var progressBar: NSProgressIndicator!
	
	@IBOutlet private weak var changelogStackView: NSStackView!
	@IBOutlet private weak var changelogTitleLabel: NSTextField!
	@IBOutlet private weak var changelogTextView: NSTextView!
	
	@IBOutlet private weak var cancelButton: NSButton!
	@IBOutlet private weak var actionButton: NSButton!
	
	// MARK: State
	
	private(set) var state: WidgetInstaller.State = .dragdrop {
		didSet {
			updateUIElementsForInstallableWidget()
		}
	}
	
	// MARK: Overrides
	
	override func viewDidLoad() {
		super.viewDidDisappear()
		setupDraggingHandler()
		configureUIElements()
		updateUIElementsForInstallableWidget()
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
		Roger.debug("[WidgetsManager][Install] - deinit")
	}
	
	// MARK: Methods
	
	private func configureUIElements() {
		// TODO: Configure UI elements styles
		changelogTitleLabel.stringValue = "widget.update.changelog.title".localized
	}
	
	private func toggleChangelogVisibility(_ visible: Bool, title: String? = nil) {
		changelogTitleLabel.stringValue = visible ? "widget.update.changelog.title".localized : (title ?? "")
		changelogTitleLabel.isHidden = !visible && title == nil
		changelogTextView.enclosingScrollView?.isHidden = !visible
		changelogStackView.isHidden = changelogTitleLabel.isHidden
	}
	
	private func updateUIElementsForInstallableWidget() {
		defer {
			actionButton.isHighlighted = true
		}
		switch state {
		case .dragdrop:
			// MARK: Drag&Drop
			titleLabel.stringValue = "widget.install.drag-here.title".localized
			bodyLabel.stringValue = "widget.install.drag-here.body".localized
			progressBar.isHidden = true
			toggleChangelogVisibility(false, title: "widget.install.drag-here.valid-formats".localized)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.choose".localized
			actionButton.isEnabled = true
		
		case .install(let widget):
			// MARK: Install
			titleLabel.stringValue = "widget.install.title".localized(widget.name)
			bodyLabel.stringValue = "widget.install.body".localized(widget.name)
			progressBar.isHidden = true
			toggleChangelogVisibility(false, title: "widget.install.click-to-continue".localized)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.install".localized
			actionButton.isEnabled = true
			
		case .update:
			// MARK: Update
			titleLabel.stringValue = "widget.update.title".localized
			bodyLabel.stringValue = "widget.update.body".localized
			progressBar.isHidden = true
			toggleChangelogVisibility(true)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.update".localized
			actionButton.isEnabled = true
			
		case .installing(let widget, let progress):
			// MARK: Installing
			titleLabel.stringValue = "widget.installing.title".localized(widget.name)
			bodyLabel.stringValue = "widget.installing.body".localized
			progressBar.isHidden = false
			progressBar.startAnimation(nil)
			progressBar.doubleValue = progress
			toggleChangelogVisibility(false)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.installing".localized
			actionButton.isEnabled = false
			
		default:
			return
		}
	}
	
	// MARK: Did select action
	@IBAction private func didSelectButton(_ button: NSButton) {
		switch button {
		case actionButton:
			switch state {
			case .dragdrop:
				chooseWidgetFile()
				
			case let .install(widget), let .update(widget):
				state = .installing(widget: widget, progress: 0)
				
			case .done:
				dismiss(nil)
			default:
				return
			}
			
		case cancelButton:
			dismiss(nil)
			
		default:
			return
		}
	}
	
	// MARK: Choose / Drag&Drop
	
	private func setupDraggingHandler() {
		guard let view = self.view as? DestinationView else {
			return
		}
		view.completion = { [weak self] path in
			do {
				let widget = try PKWidgetInfo(path: path)
				self?.state = .install(widget: widget)
			} catch {
				Roger.error(error)
				self?.state = .done(success: false)
			}
		}
	}
	
	private func chooseWidgetFile() {
		guard let window = self.view.window else {
			return
		}
		let openPanel = NSOpenPanel()
		openPanel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .localDomainMask).first
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = true
		openPanel.allowsMultipleSelection = false
		openPanel.allowedFileTypes = ["pock"]
		openPanel.beginSheetModal(for: window, completionHandler: { [weak self] result in
			if result == NSApplication.ModalResponse.OK {
				guard let self = self else {
					return
				}
				if let path = openPanel.url {
					do {
						let widget = try PKWidgetInfo(path: path)
						self.state = .install(widget: widget)
					} catch {
						Roger.error(error)
						self.state = .done(success: false)
					}
				} else {
					self.state = .done(success: false)
				}
			}
		})
	}
	
}
