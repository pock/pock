//
//  PreferencesViewController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 02/05/21.
//

import Cocoa

class PreferencesViewController: NSViewController {

    // MARK: UI Elements
	@IBOutlet private weak var versionLabel: NSTextField!
	
	/// General
	@IBOutlet private weak var generalTitleLabel: NSTextField!
	@IBOutlet private weak var allowBlankTouchBarCheckbox: NSButton!
	@IBOutlet private weak var allowBlankTouchBarDescriptionLabel: NSTextField!
	@IBOutlet private weak var launchAtLoginCheckbox: NSButton!
	
	/// Layout Styles
	@IBOutlet private weak var layoutStyleTitleLabel: NSTextField!
	@IBOutlet private weak var layoutStylesBox: NSBox!
	@IBOutlet private weak var layoutStyleWithControlStripButton: NSButton!
	@IBOutlet private weak var layoutStyleFullWidth: NSButton!
	
	/// Double `^ control` shortcut
	@IBOutlet private weak var doubleControlTitleLabel: NSTextField!
	@IBOutlet private weak var doubleControlDescriptionLabel: NSTextField!
	@IBOutlet private weak var defaultTouchBarPresentationModeLabel: NSTextField!
	@IBOutlet private weak var defaultTouchBarPresentationModePopUp: NSPopUpButton!
	@IBOutlet private weak var defaultTouchBarPresentationModeDesc: NSTextField!
	
	/// Cursor options
	@IBOutlet private weak var cursorOptionsTitleLabel: NSTextField!
	@IBOutlet private weak var enableMouseSupportCheckbox: NSButton!
	@IBOutlet private weak var showTrackingAreaCheckbox: NSButton!
	
	/// Update sections
	@IBOutlet private weak var checkForUpdatesOnceADayCheckbox: NSButton!
	@IBOutlet private weak var checkForUpdatesNowButton: NSButton!
	
	// MARK: Overrides
	
	override func viewDidLoad() {
		super.viewDidLoad()
		configureUIElements()
		localizeUIElements()
		if AppController.shared.isVisible == false {
			AppController.shared.reload(shouldFetchLatestVersions: false)
		}
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		NSApp.activate(ignoringOtherApps: true)
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		shouldAskToupdate { [weak self] newVersion in
			if let self = self, let new = newVersion {
				self.showUpdateAlert(for: new)
			}
		}
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		NSApp.deactivate()
	}
	
	deinit {
		Roger.debug("[Preferences][ViewController] - deinit")
	}
	
	// MARK: Configure UI Elements
	private func configureUIElements() {
		/// Checkboxes
		allowBlankTouchBarCheckbox.state = Preferences[.allowBlankTouchBar] == true ? .on : .off
		launchAtLoginCheckbox.state  = Preferences[.launchAtLogin] == true ? .on : .off
		enableMouseSupportCheckbox.state = Preferences[.mouseSupportEnabled] == true ? .on : .off
		showTrackingAreaCheckbox.state = Preferences[.showTrackingArea] == true ? .on : .off
		showTrackingAreaCheckbox.isEnabled = Preferences[.mouseSupportEnabled] == true
		checkForUpdatesOnceADayCheckbox.state = Preferences[.checkForUpdatesOnceADay] == true ? .on : .off
		/// Layout Style
		updateLayoutStyleUIElements()
		/// Default Touch Bar Presentation Mode
		updateDefaultPresentationModePopUpButton()
		/// Build info
		versionLabel.stringValue = Updater.fullAppVersion
	}
	
	private func localizeUIElements() {
		generalTitleLabel.stringValue = "preferences.general.title".localized
		allowBlankTouchBarCheckbox.title = "preferences.general.allow-blank-touchbar.title".localized
		allowBlankTouchBarDescriptionLabel.stringValue = "preferences.general.allow-blank-touchbar.desc".localized
		launchAtLoginCheckbox.title = "preferences.general.launch-at-login".localized
		
		layoutStyleTitleLabel.stringValue = "preferences.layout.title".localized
		
		doubleControlTitleLabel.stringValue = "preferences.double-control.title".localized
		doubleControlDescriptionLabel.stringValue = "preferences.double-control.desc".localized
		defaultTouchBarPresentationModeLabel.stringValue = "preferences.default-touchbar.shows".localized
		defaultTouchBarPresentationModeDesc.stringValue = "preferences.default-touchbar.desc".localized
		
		cursorOptionsTitleLabel.stringValue = "preferences.cursor-options.title".localized
		enableMouseSupportCheckbox.title = "preferences.cursor-options.enable-mouse-support".localized
		showTrackingAreaCheckbox.title = "preferences.cursor-options.show-tracking-area".localized
		
		checkForUpdatesOnceADayCheckbox.title = "preferences.updates.check-for-updates-once-a-day".localized
		checkForUpdatesNowButton.title = "general.action.check-for-updates".localized
	}
	
	private func updateDefaultPresentationModePopUpButton() {
		let mode: PresentationMode = Preferences[.userDefinedPresentationMode]
		defaultTouchBarPresentationModePopUp.removeAllItems()
		defaultTouchBarPresentationModePopUp.addItems(withTitles: PresentationMode.allCases.compactMap({ $0.title }))
		defaultTouchBarPresentationModePopUp.selectItem(withTitle: mode.title)
	}
	
	private func updateLayoutStyleUIElements() {
		func resizeButton(_ button: NSButton, minify: Bool) {
			if let constraint = button.constraints.first(where: { $0.identifier == "layout-style.option.width" }) {
				NSAnimationContext.runAnimationGroup { context in
					context.duration = 0.2725
					constraint.animator().constant = minify ? 132 : 256
					button.animator().alphaValue = minify ? 0.525 : 1.0
				}
			}
		}
		let style: LayoutStyle = Preferences[.layoutStyle]
		switch style {
		case .withControlStrip:
			resizeButton(layoutStyleWithControlStripButton, minify: false)
			resizeButton(layoutStyleFullWidth, minify: true)
		case .fullWidth:
			resizeButton(layoutStyleWithControlStripButton, minify: true)
			resizeButton(layoutStyleFullWidth, minify: false)
		}
		layoutStylesBox.title = style.title
	}
	
	// MARK: Actions
	
	@IBAction private func didChangeLayoutStyle(for button: NSButton) {
		let style: LayoutStyle
		switch button {
		case layoutStyleWithControlStripButton:
			style = .withControlStrip
		case layoutStyleFullWidth:
			style = .fullWidth
		default:
			return
		}
		guard Preferences[.layoutStyle] != style else {
			return
		}
		Preferences[.layoutStyle] = style.rawValue
		updateLayoutStyleUIElements()
		async(after: 0.4) {
			NotificationCenter.default.post(name: .shouldReloadPock, object: nil)
		}
	}
	
	@IBAction private func didChangeDefaultTouchBarPresentationMode(_ button: NSPopUpButton) {
		let presentationMode = PresentationMode.allCases.without(.undefined)[defaultTouchBarPresentationModePopUp.indexOfSelectedItem]
		if Preferences[.userDefinedPresentationMode] as PresentationMode != presentationMode {
			Preferences[.userDefinedPresentationMode] = presentationMode.rawValue
			if AppController.shared.pockTouchBarController?.isVisible == nil || false {
				TouchBarHelper.setPresentationMode(to: presentationMode)
			}
		}
	}
	
	@IBAction private func didChangePreferencesOption(for button: NSButton) {
		let key: Preferences.Keys
		var shouldReloadPock: Bool = true
		let newValue = button.state == .on
		switch button {
		case allowBlankTouchBarCheckbox:
			key = .allowBlankTouchBar
		
		case launchAtLoginCheckbox:
			key = .launchAtLogin
			shouldReloadPock = false
		
		case enableMouseSupportCheckbox:
			key = .mouseSupportEnabled
			showTrackingAreaCheckbox.isEnabled = newValue
		
		case showTrackingAreaCheckbox:
			key = .showTrackingArea
		
		case checkForUpdatesOnceADayCheckbox:
			key = .checkForUpdatesOnceADay
			shouldReloadPock = false
			
		default:
			return
		}
		Preferences[key] = newValue
		if shouldReloadPock {
			async {
				NotificationCenter.default.post(name: .shouldReloadPock, object: nil)
			}
		}
		if button == checkForUpdatesOnceADayCheckbox {
			async {
				NotificationCenter.default.post(name: .shouldEnableAutomaticUpdates, object: nil)
			}
		}
	}
	
	// MARK: Core-update stuff
	
	private func shouldAskToupdate(_ completion: @escaping (Version?) -> Void) {
		AppController.shared.fetchLatestVersions { [completion] in
			let currentVersion = Updater.fullAppVersion
			if let core = Updater.cachedLatestReleases?.core, core.name > currentVersion {
				completion(core)
			} else {
				completion(nil)
			}
		}
	}
	
	@IBAction private func checkForUpdates(_ sender: NSButton) {
		checkForUpdatesNowButton.isEnabled = false
		checkForUpdatesNowButton.title = "general.action.checking".localized
		shouldAskToupdate { [weak self] newVersion in
			guard let self = self else {
				return
			}
			self.checkForUpdatesNowButton.title = "general.action.check-for-updates".localized
			self.checkForUpdatesNowButton.isEnabled = true
			self.showUpdateAlert(for: newVersion)
		}
	}
	
	private func showUpdateAlert(for version: Version?) {
		let currentVersion = Updater.fullAppVersion
		if let newVersion = version {
			self.showAlert(
				title: "preferences.updates.new-version-available.title".localized,
				message: "preferences.updates.new-version-available.message".localized(currentVersion, newVersion.name),
				buttons: ["general.action.update".localized, "general.action.later".localized],
				completion: { response in
					switch response {
					case .alertFirstButtonReturn:
						async {
							AppController.shared.openWebsite(newVersion.link)
						}
					default:
						return
					}
				}
			)
		} else {
			self.showAlert(
				title: "preferences.updates.already-on-latest-version.title".localized(currentVersion),
				message: "preferences.updates.already-on-latest-version.message".localized
			)
		}
	}
	
	private func showAlert(title: String, message: String, buttons: [String] = [], completion: ((NSApplication.ModalResponse) -> Void)? = nil) {
		async { [weak self] in
			guard let window = self?.view.window else {
				return
			}
			let alert = NSAlert()
			alert.alertStyle = NSAlert.Style.informational
			alert.messageText = title
			alert.informativeText = message
			for buttonTitle in buttons {
				alert.addButton(withTitle: buttonTitle)
			}
			alert.beginSheetModal(for: window, completionHandler: completion)
		}
	}
	
}
