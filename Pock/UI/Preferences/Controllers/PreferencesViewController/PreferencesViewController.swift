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
	
	/// Double `^ control` shortcut
	@IBOutlet private weak var doubleControlTitleLabel: NSTextField!
	@IBOutlet private weak var doubleControlDescriptionLabel: NSTextField!
	
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
		Roger.debug("[Preferences][ViewController] - deinit")
	}
	
	// MARK: Configure UI Elements
	private func configureUIElements() {
		/// Checkboxes
		self.allowBlankTouchBarCheckbox.state = Preferences[.allowBlankTouchBar] == true ? .on : .off
		self.launchAtLoginCheckbox.state  = Preferences[.launchAtLogin] == true ? .on : .off
		// TODO: Control Strip style
		self.enableMouseSupportCheckbox.state = Preferences[.mouseSupportEnabled] == true ? .on : .off
		self.showTrackingAreaCheckbox.state = Preferences[.showTrackingArea] == true ? .on : .off
		self.showTrackingAreaCheckbox.isEnabled = Preferences[.mouseSupportEnabled] == true
		self.checkForUpdatesOnceADayCheckbox.state = Preferences[.checkForUpdatesOnceADay] == true ? .on : .off
		/// Build info
		// TODO: Show current version number
	}
	
	private func localizeUIElements() {
		generalTitleLabel.stringValue = "preferences.general".localized
		allowBlankTouchBarCheckbox.title = "preferences.general.allow-blank-touchbar.title".localized
		allowBlankTouchBarDescriptionLabel.stringValue = "preferences.general.allow-blank-touchbar.desc".localized
		launchAtLoginCheckbox.title = "preferences.general.launch-ar-login".localized
		doubleControlTitleLabel.stringValue = "preferences.double-control.title".localized
		doubleControlDescriptionLabel.stringValue = "preferences.double-control.desc".localized
		cursorOptionsTitleLabel.stringValue = "preferences.cursor-options".localized
		enableMouseSupportCheckbox.title = "preferences.cursor-options.enable-mouse-support".localized
		showTrackingAreaCheckbox.title = "preferences.cursor-options.show-tracking-area".localized
		checkForUpdatesOnceADayCheckbox.title = "preferences.updates.check-for-updates-once-a-day".localized
		checkForUpdatesNowButton.stringValue = "preferences.updates.check-for-updates".localized
	}
	
	// MARK: Actions
	
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
	}
	
}
