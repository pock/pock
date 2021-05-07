//
//  EmptyTouchBarController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 07/05/21.
//

import Cocoa
import PockKit

internal class EmptyTouchBarController: PKTouchBarMouseController {

	internal enum State {
		case empty, installDefault
	}
	
	internal var state: State = .empty
	
    // MARK: UI Elements
	@IBOutlet private weak var titleLabel: NSTextField!
	@IBOutlet private weak var subtitleLabel: NSTextField!
	@IBOutlet private weak var informativeLabel: NSTextField!
	@IBOutlet private weak var actionIconView: NSImageView!
	@IBOutlet private weak var actionButton: NSButton!
	
	// MARK: Mouse Support
	private var buttonWithMouseOver: NSButton?
	private var touchBarView: NSView {
		guard let views = NSFunctionRow._topLevelViews() as? [NSView], let view = views.last else {
			fatalError("Touch Bar is not available.")
		}
		return view
	}
	public override var visibleRectWidth: CGFloat {
		get {
			return touchBarView.visibleRect.width
		} set {
			super.visibleRectWidth = newValue
		}
	}
	public override var parentView: NSView! {
		get {
			return touchBarView
		} set {
			super.parentView = newValue
		}
	}
	
	override func present() {
		super.present()
		updateUIState()
	}
	
	private func updateUIState() {
		switch state {
		case .empty:
			informativeLabel.stringValue = "widgets.empty.add-widgets-to-pock".localized
			actionButton.tag = 0
			actionButton.title = "general.action.customize".localized
			
		case .installDefault:
			informativeLabel.stringValue = "widgets.defaults.tap-to-install".localized
			actionButton.tag = 1
			actionButton.title = "general.action.install".localized
		}
		titleLabel.stringValue = "general.welcome-to-pock".localized
		subtitleLabel.stringValue = "general.pock-widgets-manager".localized
		async(after: 0.5) { [weak self] in
			self?.addIconViewAnimation()
		}
	}
	
	@IBAction private func actionButtonPressed(_ button: NSButton) {
		defer {
			dismiss()
		}
		switch button.tag {
		case 0:
			AppController.shared.openPockCustomizationPalette()
		case 1:
			AppController.shared.reInstallDefaultWidgets()
		default:
			return
		}
	}
	
	// MARK: Mouse stuff
	public override func screenEdgeController(_ controller: PKScreenEdgeController, mouseClickAtLocation location: NSPoint, in view: NSView) {
		guard let button = button(at: location) else {
			return
		}
		actionButtonPressed(button)
	}
	
	public override func updateCursorLocation(_ location: NSPoint?) {
		super.updateCursorLocation(location)
		buttonWithMouseOver?.isHighlighted = false
		buttonWithMouseOver = nil
		buttonWithMouseOver = button(at: location)
		buttonWithMouseOver?.isHighlighted = true
	}
	
	private func button(at location: NSPoint?) -> NSButton? {
		guard let view = parentView.subview(in: parentView, at: location, of: "NSTouchBarItemContainerView") else {
			return nil
		}
		return view.findViews(subclassOf: NSButton.self).first
	}
	
}

// MARK: Icon bounce animation
extension EmptyTouchBarController {
	private func addIconViewAnimation() {
		actionIconView.superview?.layout()
		let slideAnimation = CABasicAnimation(keyPath: "position.x")
		slideAnimation.duration  = 0.475
		slideAnimation.fromValue = (actionIconView.superview?.frame.origin.x ?? 0) + 3.3525
		slideAnimation.toValue   = (actionIconView.superview?.frame.origin.x ?? 0) - 1.3525
		slideAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
		slideAnimation.autoreverses = true
		slideAnimation.repeatCount = .greatestFiniteMagnitude
		actionIconView.superview?.layer?.add(slideAnimation, forKey: "bounce_animation")
	}
	private func removeIconViewAnimation() {
		actionIconView.superview?.layer?.removeAnimation(forKey: "bounce_animation")
	}
}
