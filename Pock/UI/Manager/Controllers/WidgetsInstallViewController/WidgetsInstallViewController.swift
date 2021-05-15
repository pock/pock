//
//  WidgetsInstallViewController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/05/21.
//

import Cocoa

// swiftlint:disable file_length
// swiftlint:disable type_body_length
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
		progressBar.minValue = 0
		progressBar.maxValue = 1
		changelogTitleLabel.stringValue = "widget.update.changelog.title".localized
	}
	
	private func toggleChangelogVisibility(_ visible: Bool, title: String? = nil) {
		changelogTitleLabel.stringValue = visible ? "widget.update.changelog.title".localized : (title ?? "")
		changelogTitleLabel.isHidden = !visible && title == nil
		changelogTextView.enclosingScrollView?.isHidden = !visible
		changelogStackView.isHidden = changelogTitleLabel.isHidden
	}
	
	private func toggleProgressBarStyle(isIndeterminated: Bool, progress: Double = 0) {
		defer {
			progressBar.isHidden = false
		}
		if isIndeterminated {
			progressBar.doubleValue = 0
			progressBar.isIndeterminate = true
			progressBar.startAnimation(nil)
		} else {
			progressBar.stopAnimation(nil)
			progressBar.doubleValue = progress
			progressBar.isIndeterminate = false
		}
	}
	
	// swiftlint:disable cyclomatic_complexity
	// swiftlint:disable function_body_length
	private func updateUIElementsForInstallableWidget() {
		// MARK: State
		defer {
			setupDraggingHandler()
			actionButton.isHighlighted = true
		}
		switch state {
		case .installDefault:
			// MARK: Install default widgets
			titleLabel.stringValue = "widget.install.default.title".localized
			bodyLabel.stringValue = "widget.install.default.body".localized
			progressBar.isHidden = true
			toggleChangelogVisibility(false)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.start".localized
			actionButton.isEnabled = true
			
		case .installingDefault(let progress):
			// MARK: Installing default widgets
			titleLabel.stringValue = "widget.installing.title".localized(progress.name)
			bodyLabel.stringValue = "widget.installing.default.body".localized(progress.processed, progress.total)
			toggleProgressBarStyle(isIndeterminated: false, progress: progress.progress)
			toggleChangelogVisibility(false)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.downloading".localized
			actionButton.isEnabled = false
			
		case .installedDefault(let errors):
			// MARK: Installed default widgets
			if let errors = errors {
				titleLabel.stringValue = "widget.error.title".localized
				bodyLabel.stringValue = "widget.error.body".localized(errors)
			} else {
				titleLabel.stringValue = "widget.install.success.title".localized
				bodyLabel.stringValue = "widget.installed.default.success.body".localized
			}
			actionButton.title = "general.action.relaunch".localized
			progressBar.isHidden = true
			toggleChangelogVisibility(false)
			cancelButton.isHidden = true
			actionButton.isEnabled = true
		
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
			
		case .installArchive(let url):
			// MARK: Install (archive)
			let name = url.deletingPathExtension().lastPathComponent
			titleLabel.stringValue = "widget.install.title".localized(name)
			bodyLabel.stringValue = "widget.install.body".localized(name)
			progressBar.isHidden = true
			toggleChangelogVisibility(false, title: "widget.install.click-to-continue".localized)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.install".localized
			actionButton.isEnabled = true
			
		case .update(let widget, let version):
			// MARK: Update
			titleLabel.stringValue = "widget.update.title".localized(widget.name)
			bodyLabel.stringValue = "widget.update.body".localized(widget.fullVersion, version.name)
			progressBar.isHidden = true
			toggleChangelogVisibility(true)
			changelogTextView.string = version.changelog
			cancelButton.title = "general.action.later".localized
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
			toggleProgressBarStyle(isIndeterminated: false, progress: progress)
			toggleChangelogVisibility(false)
			cancelButton.title = "general.action.cancel".localized
			actionButton.title = "general.action.downloading".localized
			actionButton.isEnabled = false
		
		case .error(let error):
			// MARK: Error
			titleLabel.stringValue = "widget.error.title".localized
			bodyLabel.stringValue = "widget.error.body".localized(error.description)
			progressBar.isHidden = true
			toggleChangelogVisibility(false)
			cancelButton.isHidden = true
			actionButton.title = "general.action.close".localized
			actionButton.isEnabled = true
			
		case .removed(let widget), .installed(let widget), .updated(let widget):
			switch state {
			case .removed:
				// MARK: Removed
				titleLabel.stringValue = "widget.remove.success.title".localized
				bodyLabel.stringValue = "widget.remove.success.body".localized(widget.name)
				actionButton.title = "general.action.relaunch".localized
			case .installed:
				// MARK: Installed
				titleLabel.stringValue = "widget.install.success.title".localized
				bodyLabel.stringValue = "widget.install.success.body".localized(widget.name)
				actionButton.title = "general.action.relaunch".localized
			case .updated:
				// MARK: Updated
				titleLabel.stringValue = "widget.update.success.title".localized
				bodyLabel.stringValue = "widget.update.success.body".localized(widget.name)
				actionButton.title = "general.action.relaunch".localized
			default:
				return
			}
			progressBar.isHidden = true
			toggleChangelogVisibility(false)
			cancelButton.isHidden = true
			actionButton.isEnabled = true
			
		}
	}
	
	// MARK: Did select action
	@IBAction private func didSelectButton(_ button: NSButton) {
		// MARK: Actions
		switch button {
		case actionButton:
			switch state {
			case .installDefault:
				// MARK: Install default widgets
				installDefaultWidgets()
			
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
						self?.state = .removed(widget: widget)
					}
				}
			case let .install(widget):
				// MARK: Install
				state = .installing(widget: widget)
				WidgetsInstaller().installWidget(widget) { [weak self] _, error in
					if let error = error {
						self?.state = .error(error)
					} else {
						self?.state = .installed(widget: widget)
					}
				}
			case let .installArchive(url):
				// MARK: Install (archive)
				let name = url.deletingPathExtension().lastPathComponent
				WidgetsInstaller().extractAndInstall(name, atLocation: url, removeSource: false) { [weak self] widget, error in
					if let error = error {
						self?.state = .error(error)
					} else if let widget = widget {
						self?.state = .installed(widget: widget)
					} else {
						self?.state = .error(WidgetsInstallerError.invalidBundle(reason: nil))
					}
				}
			case let .update(widget, version):
				// MARK: Update
				state = .downloading(widget: widget, progress: 0)
				WidgetsInstaller().updateWidget(
					widget,
					version: version,
					progress: { [weak self] progress in
						self?.state = .downloading(widget: widget, progress: progress)
					},
					completion: { [weak self] _, error in
						if let error = error {
							self?.state = .error(error)
						} else {
							self?.state = .updated(widget: widget)
						}
					}
				)
			case .installed, .installedDefault:
				// MARK: Relaunch on default widgets installation
				AppController.shared.relaunch()
				
			case .removed, .updated:
				// MARK: Relaunch
				dismiss(nil)
				async {
					AppController.shared.relaunch()
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
// swiftlint:enable type_body_length

extension WidgetsInstallViewController {
	
	// MARK: Install default widgets
	private func installDefaultWidgets() {
		WidgetsInstaller().installDefaultWidgets(
		progress: { [weak self] (widgetName, _, processed, total) in
			self?.state = .installingDefault((widgetName, Double(processed) / Double(total), processed, total))
		},
		completion: { [weak self] errors in
			var errorStrings: String?
			if errors.values.contains(where: { $0 != nil }) {
				errorStrings = ""
				for (key, value) in errors {
					if let error = value {
						errorStrings? += "\(key) \("base.widget".localized): \(error.description)\n"
					}
				}
			}
			self?.state = .installedDefault(errorStrings)
		})
	}
	
	// MARK: Choose / Drag&Drop
	private func setupDraggingHandler() {
		guard let view = self.view as? DestinationView else {
			return
		}
		switch state {
		case .dragdrop:
			view.canAcceptDraggedElement = true
			view.completion = { [weak self] path in
				self?.handleFileAtPath(path)
			}
		default:
			view.canAcceptDraggedElement = false
			view.completion = nil
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
		openPanel.allowedFileTypes = ["pock", "pkarchive"]
		openPanel.beginSheetModal(for: window, completionHandler: { [weak self] result in
			if result == NSApplication.ModalResponse.OK {
				guard let self = self else {
					return
				}
				if let path = openPanel.url {
					self.handleFileAtPath(path)
				} else {
					self.state = .error(WidgetsInstallerError.invalidBundle(reason: "error.unknown".localized))
				}
			}
		})
	}
	
	private func handleFileAtPath(_ path: URL) {
		var pathURL: URL = path
		if path.scheme == nil {
			pathURL = URL(fileURLWithPath: path.path)
		}
		switch pathURL.pathExtension {
		case "pock":
			do {
				let widget = try PKWidgetInfo(path: pathURL)
				self.state = .install(widget: widget)
			} catch {
				Roger.error(error)
				self.state = .error(WidgetsInstallerError.invalidBundle(reason: error.localizedDescription))
			}
		case "pkarchive":
			self.state = .installArchive(url: pathURL)
		default:
			self.state = .error(WidgetsInstallerError.invalidBundle(reason: "error.unknown".localized))
		}
	}
}
// swiftlint:enable file_length
