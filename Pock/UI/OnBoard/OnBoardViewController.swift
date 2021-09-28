//
//  OnBoardViewController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 13/05/21.
//

import Cocoa

class OnBoardViewController: NSViewController {

	// MARK: UI Elements
	
	@IBOutlet private weak var titleLabel: NSTextField!
	@IBOutlet private weak var subtitleLabel: NSTextField!
	@IBOutlet private weak var defaultWidgetsStackView: NSStackView!
	@IBOutlet private weak var defaultWidgetsInstallLabel: NSTextField!
	@IBOutlet private weak var openPreferencesButton: NSButton!
	@IBOutlet private weak var continueWithDefaultSettingsButton: NSButton!
	
	private var animatableViews: [NSTextField] {
		let substack: [NSStackView] = defaultWidgetsStackView.findViews()
		var views: [NSTextField] = []
		for stack in substack {
			views += stack.arrangedSubviews.filter({ $0 is NSTextField }) as? [NSTextField] ?? []
		}
		return views
	}
	
	// MARK: Overrides
	
	override var title: String? {
		get {
			return "general.welcome-to-pock".localized
		}
		set {
			view.window?.title = newValue ?? ""
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		Preferences[.didShowOnBoard] = true
		configureUIElements()
		animate()
    }
	
	override func viewWillAppear() {
		super.viewWillAppear()
		NSApp.activate(ignoringOtherApps: true)
	}
	
	override func viewDidDisappear() {
		super.viewDidDisappear()
		NSApp.deactivate()
	}
	
	deinit {
		Roger.debug("[OnBoard][ViewController] - deinit")
	}
	
	// MARK: Methods
	
	private func configureUIElements() {
		titleLabel.stringValue = "onboard.title".localized
		subtitleLabel.stringValue = "onboard.body".localized
		defaultWidgetsInstallLabel.stringValue = "onboard.footer".localized
		openPreferencesButton.title = "onboard.open-preferences".localized
		continueWithDefaultSettingsButton.title = "onboard.continue-with-default-settings".localized
		continueWithDefaultSettingsButton.isHighlighted = true
	}
	
	private func animate() {
		for view in animatableViews {
			async(after: .random(in: 0...2)) { [weak view] in
				view?.animate(
					key: "kBounceAnimationKey",
					keyPath: "transform.scale",
					fromValue: .random(in: 0.56...0.88),
					toValue: 1.2,
					duration: .random(in: 2.25...2.75),
					autoreverse: true
				)
			}
		}
	}
	
	@IBAction private func didSelectButton(_ button: NSButton) {
		defer {
			view.window?.close()
		}
		switch button {
		case openPreferencesButton:
			AppController.shared.openController(PreferencesViewController())
		default:
			return
		}
	}
    
}

fileprivate extension NSView {
	func animate(
		key: String,
		keyPath: String,
		fromValue: CGFloat = 0.86,
		toValue: CGFloat = 1,
		duration: CFTimeInterval = 2.75,
		autoreverse: Bool = false,
		removeOnCompletion: Bool = false,
		repeatCount: Float = Float.infinity,
		timing: CAMediaTimingFunctionName = .easeInEaseOut,
		anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
	) {
		wantsLayer = true
		let bounce                   = CABasicAnimation(keyPath: keyPath)
		bounce.fromValue             = fromValue
		bounce.toValue               = toValue
		bounce.duration              = duration
		bounce.autoreverses          = autoreverse
		bounce.repeatCount           = repeatCount
		bounce.isRemovedOnCompletion = removeOnCompletion
		bounce.timingFunction        = CAMediaTimingFunction(name: timing)
		let frame = self.layer?.frame
		self.layer?.anchorPoint = anchorPoint
		self.layer?.frame = frame ?? .zero
		self.layer?.add(bounce, forKey: "")
	}
}
