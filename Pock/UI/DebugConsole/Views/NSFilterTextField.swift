//
//  NSFilterTextField.swift
//  Pock
//
//  Created by Pierluigi Galdi on 26/06/21.
//

import Foundation

class NSTextFieldWithShortcuts: NSTextField {
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let commandKeyFlags = NSEvent.ModifierFlags.command.rawValue
        let indipendentFlagsMask = NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
        guard event.type == .keyDown, event.modifierFlags.rawValue & indipendentFlagsMask == commandKeyFlags else {
            return false
        }
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "x":
            return NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
        case "c":
            return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
        case "v":
            return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
            
        default:
            return false
        }
    }
}

class NSFilterTextField: NSView {
    
    // MARK: UI Elements
    
    @IBOutlet public private(set) weak var textField: NSTextFieldWithShortcuts!
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
        textField.placeholderString = "Filter"
        setNumberOfOccurrencies(0)
    }
 
    // MARK: Actions
    
    public func setNumberOfOccurrencies(_ number: Int) {
        occurrenciesCountLabel.stringValue = "\(number)"
        occurrenciesCountLabel.isHidden = textField.stringValue.isEmpty
        clearButton.isHidden = textField.stringValue.isEmpty
    }
    
}
