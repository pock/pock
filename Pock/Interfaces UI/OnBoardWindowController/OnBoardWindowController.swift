//
//  OnBoardWindowController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 07/01/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Cocoa

class OnBoardWindowController: NSWindowController {

	/// Core
	public override var windowNibName: NSNib.Name? {
		return NSNib.Name("OnBoardWindowController")
	}
	
	/// UI Elements
	@IBOutlet private weak var titleLabel: 	 NSTextField!
	@IBOutlet private weak var bodyLabel: 	 NSTextField!
	@IBOutlet private weak var tooltipLabel: NSTextField!
	@IBOutlet private weak var animatedView: NSImageView!
	@IBOutlet private weak var animatableStack: NSStackView!
	
	private var animatableViews: [NSTextField] {
		let substack: [NSStackView] = animatableStack.findViews()
		var views: [NSTextField] = []
		for stack in substack {
			views += stack.arrangedSubviews.filter({ $0 is NSTextField }) as? [NSTextField] ?? []
		}
		return views
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		self.localize()
		self.stylize()
		self.animate()
	}
	
	private func localize() {
		self.titleLabel.stringValue = "Get the Most Out of Your MacBook Pro Touch Bar".localized
		self.bodyLabel.stringValue = "Pock comes with default widgets that let you access the most essential information and functionality of your frequently used controls and services.".localized
		self.tooltipLabel.stringValue = "Follow the instructions in the Touch Bar to install default widgets".localized
	}
	
	private func stylize() {
		self.animatedView.wantsLayer = true
		self.animatedView.layer?.cornerRadius = 8
		self.animatedView.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
		self.window?.level = .floating
		self.window?.center()
	}
	
	private func animate() {
		for view in animatableViews {
			async(after: .random(in: 0...2)) { [weak view] in
				view?.animate(key: "kBounceAnimationKey", keyPath: "transform.scale",
							  from: .random(in: 0.56...0.86), to: 1.2,
							  duration: .random(in: 2.25...2.75), autoreverse: true)
			}
		}
	}
    
}

fileprivate extension NSView {
	func animate(key: String,
				 keyPath: String,
				 from: CGFloat = 0.86,
				 to: CGFloat = 1,
				 duration: CFTimeInterval = 2.75,
				 autoreverse: Bool = false,
				 removeOnCompletion: Bool = false,
				 repeatCount: Float = Float.infinity,
				 timing: CAMediaTimingFunctionName = .easeInEaseOut,
				 anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)) {
		wantsLayer = true
		let bounce                   = CABasicAnimation(keyPath: keyPath)
		bounce.fromValue             = from
		bounce.toValue               = to
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
