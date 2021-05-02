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
	@IBOutlet private weak var layoutStyleDescriptionLabel: NSTextField!
	
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
		allowBlankTouchBarCheckbox.state = Preferences[.allowBlankTouchBar] == true ? .on : .off
		launchAtLoginCheckbox.state  = Preferences[.launchAtLogin] == true ? .on : .off
		enableMouseSupportCheckbox.state = Preferences[.mouseSupportEnabled] == true ? .on : .off
		showTrackingAreaCheckbox.state = Preferences[.showTrackingArea] == true ? .on : .off
		showTrackingAreaCheckbox.isEnabled = Preferences[.mouseSupportEnabled] == true
		checkForUpdatesOnceADayCheckbox.state = Preferences[.checkForUpdatesOnceADay] == true ? .on : .off
		/// Layout Style
		updateLayoutStyleUIElements()
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
	
	private func updateLayoutStyleUIElements() {
		func resizeButton(_ button: NSButton, minify: Bool) {
			if let constraint = button.constraints.first(where: { $0.identifier == "layout-style.option.width" }) {
				NSAnimationContext.runAnimationGroup { context in
					context.duration = 0.3125
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
