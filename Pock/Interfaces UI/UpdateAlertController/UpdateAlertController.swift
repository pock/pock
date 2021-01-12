//
//  UpdateAlertController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 12/01/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Cocoa

class UpdateAlertController: NSViewController {

	/// UI Elements
	@IBOutlet private weak var iconView: NSImageView!
	@IBOutlet private weak var titleLabel: NSTextField!
	@IBOutlet private weak var subtitleLabel: NSTextField!
	@IBOutlet private weak var changelogLabel: NSTextField!
	@IBOutlet private weak var changelogTextView: NSTextView!
	@IBOutlet private weak var remindLaterButton: NSButton!
	@IBOutlet private weak var updateNowButton: NSButton!
	
	/// Data
	private var icon: NSImage?
	private var version: Version!
	private var fromVersion: String!
	private var packageName: String!
	private var updateHandle: (() -> Void)?
	
	private var titleValue: String {
		return "A new version is available for".localized + " \(packageName!)"
	}
	private var subtitleValue: String {
		let updateTo = "Would you like to update to version".localized
		let fromVers = "from version".localized
		return "\(updateTo) \(version.name) \(fromVers) \(fromVersion!)?"
	}
	
	convenience init?(newVersion:   Version?,
					  fromVersion:  String,
					  packageName:  String,
					  icon:			NSImage? = nil,
					  updateHandle: (() -> Void)?) {
		guard let new = newVersion else {
			return nil
		}
		self.init(nibName: "UpdateAlertController", bundle: .main)
		self.icon 		  = icon
		self.version 	  = new
		self.fromVersion  = fromVersion
		self.packageName  = packageName
		self.updateHandle = updateHandle
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if let icon = self.icon {
			self.iconView.image = icon
		}
		self.titleLabel.stringValue = titleValue
		self.subtitleLabel.stringValue = subtitleValue
		self.changelogLabel.stringValue = "Changelog".localized
		self.changelogTextView.string = version.changelog
		self.changelogTextView.sizeToFit()
		self.remindLaterButton.title = "Remind me later".localized
		self.updateNowButton.title = "Update now".localized
		self.updateNowButton.isHighlighted = true
	}
	
	@IBAction private func updateLater(_ sender: Any?) {
		self.dismiss(nil)
	}
	
	@IBAction private func updateNow(_ sender: Any?) {
		self.dismiss(nil)
		self.updateHandle?()
	}
    
}
