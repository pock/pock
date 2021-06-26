//
//  NSFilterTextField.swift
//  Pock
//
//  Created by Pierluigi Galdi on 26/06/21.
//

import Foundation

class NSFilterTextField: NSView {
    
    // MARK: UI Elements
    
    @IBOutlet public private(set) weak var textField: NSTextField!
    @IBOutlet public private(set) weak var occurrenciesCountLabel: NSTextField!
    @IBOutlet public private(set) weak var clearButton: NSButton!
    
    // MARK: Overrides
    
    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.275).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.controlTextColor.withAlphaComponent(0.275).cgColor
        layer?.cornerRadius = 8
        textField.focusRingType = .none
        textField.stringValue = ""
        textField.placeholderString = "Filter" // TODO: Should be localized?
        setNumberOfOccurrencies(0)
    }
 
    // MARK: Actions
    
    public func setNumberOfOccurrencies(_ number: Int) {
        occurrenciesCountLabel.stringValue = "\(number)"
        occurrenciesCountLabel.isHidden = textField.stringValue.isEmpty
        clearButton.isHidden = textField.stringValue.isEmpty
    }
    
}
