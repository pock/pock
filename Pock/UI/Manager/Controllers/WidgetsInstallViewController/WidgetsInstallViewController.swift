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
	
	internal var state: WidgetsInstaller.State = .dragdrop {
		didSet {
			if isViewLoaded {
				updateUIElementsForInstallableWidget()
			}
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
		view.window?.styleMask.remove(.resizable)
		changelogTitleLabel.stringValue = "widget.update.changelog.title".localized
	}
	
	private func toggleChangelogVisibility(_ visible: Bool, title: String? = nil) {
		changelogTitleLabel.stringValue = visible ? "widget.update.changelog.title".localized : (title ?? "")
		changelogTitleLabel.isHidden = !visible && title == nil
		changelogTextView.enclosingScrollView?.isHidden = !visible
		changelogStackView.isHidden = changelogTitleLabel.isHidden
	}
	
	private func toggleProgressBarStyle(isIndeterminated: Bool, value: Double = 0) {
		defer {
			progressBar.isHidden = false
		}
		if isIndeterminated {
			progressBar.doubleValue = 0
			progressBar.isIndeterminate = true
			progressBar.startAnimation(nil)
		} else {
			progressBar.stopAnimation(nil)
			progressBar.doubleValue = value
			progressBar.isIndeterminate = false
		}
	}
	
	// swiftlint:disable cyclomatic_complexity
	// swiftlint:disable function_body_length
	private func updateUIElementsForInstallableWidget() {
		// MARK: State
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
		
		case .remove(let widget):
			// MARK: Uninstall
			titleLabel.stringValue = "widget.remove.title".localized(widget.name)
			bodyLabel.stringValue = "widget.remove.body".localized(widget.name)
			progressBar.isHidden = true
			toggleChangelogVisibility(false, title: "widget.remove.click-to-continue".localized)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.remove".localized
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
		
		case .removing(let widget):
			// MARK: Uninstalling
			titleLabel.stringValue = "widget.removing.title".localized(widget.name)
			bodyLabel.stringValue = "widget.removing.body".localized
			toggleProgressBarStyle(isIndeterminated: true)
			toggleChangelogVisibility(false)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.removing".localized
			actionButton.isEnabled = false
			
		case .installing(let widget):
			// MARK: Installing
			titleLabel.stringValue = "widget.installing.title".localized(widget.name)
			bodyLabel.stringValue = "widget.installing.body".localized
			toggleProgressBarStyle(isIndeterminated: true)
			toggleChangelogVisibility(false)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.installing".localized
			actionButton.isEnabled = false
			
		case .downloading(let widget, let progress):
			// MARK: Downloading
			titleLabel.stringValue = "widget.downloading.title".localized(widget.name)
			bodyLabel.stringValue = "widget.downloading.body".localized
			toggleProgressBarStyle(isIndeterminated: false, value: progress)
			toggleChangelogVisibility(false)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.downloading".localized
			actionButton.isEnabled = false
		
		case .error(let error):
			// MARK: Success
			switch error {
			case .cantRemove:
				titleLabel.stringValue = "widget.remove.error.title".localized
			default:
				titleLabel.stringValue = "widget.error.title".localized
			}
			bodyLabel.stringValue = "widget.error.body".localized(error.description)
			progressBar.isHidden = true
			toggleChangelogVisibility(false)
			cancelButton.isHidden = true
			actionButton.title = "general.action.close".localized
			actionButton.isEnabled = true
			
		case .success(let widget, let removed):
			// MARK: Success
			if removed {
				titleLabel.stringValue = "widget.remove.success.title".localized
				bodyLabel.stringValue = "widget.remove.success.body".localized(widget.name)
			} else {
				titleLabel.stringValue = "widget.install.success.title".localized
				bodyLabel.stringValue = "widget.install.success.body".localized(widget.name)
			}
			progressBar.isHidden = true
			toggleChangelogVisibility(false)
			cancelButton.isHidden = true
			actionButton.title = "general.action.reload".localized
			actionButton.isEnabled = true
			
		}
	}
	
	// MARK: Did select action
	
	@IBAction private func didSelectButton(_ button: NSButton) {
		
		// MARK: Actions
		switch button {
		case actionButton:
			switch state {
			case .dragdrop:
				// MARK: Drag&Drop
				chooseWidgetFile()
				
			case let .remove(widget):
				// MARK: Uninstall
				state = .removing(widget: widget)
				WidgetsInstaller().uninstallWidget(widget) { [weak self] error in
					if let error = error {
						self?.state = .error(error)
					} else {
						self?.state = .success(widget: widget, removed: true)
					}
				}
				
			case let .install(widget):
				// MARK: Install
				state = .installing(widget: widget)
				WidgetsInstaller().installWidget(widget) { [weak self] error in
					if let error = error {
						self?.state = .error(error)
					} else {
						self?.state = .success(widget: widget, removed: false)
					}
				}
				
			case let .update(widget):
				// MARK: Update
				state = .downloading(widget: widget, progress: 0)
				WidgetsInstaller().updateWidget(
					widget,
					progress: { [weak self] progress in
						self?.state = .downloading(widget: widget, progress: progress)
					},
					completion: { [weak self] error in
						if let error = error {
							self?.state = .error(error)
						} else {
							self?.state = .install(widget: widget)
						}
					}
				)
				
			case .success:
				// MARK: Success
				AppController.shared.reload()
				async { [weak self] in
					self?.dismiss(nil)
				}
				
			case .error:
				// MARK: Error
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
	// swiftlint:enable function_body_length
	// swiftlint:enable cyclomatic_complexity
	
}

extension WidgetsInstallViewController {
	
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
				self?.state = .error(.invalidBundle(reason: error.localizedDescription))
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
						self.state = .error(.invalidBundle(reason: error.localizedDescription))
					}
				} else {
					self.state = .error(.invalidBundle(reason: "error.unknown".localized))
				}
			}
		})
	}
	
}
