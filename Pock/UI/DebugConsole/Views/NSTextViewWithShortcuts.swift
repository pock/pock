//
//  NSTextViewShortcuts.swift
//  Pock
//
//  Created by Pierluigi Galdi on 27/06/21.
//

import Foundation

public class NSTextViewWithShortcuts: NSTextView {
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let commandKeyFlags = NSEvent.ModifierFlags.command.rawValue
        let indipendentFlagsMask = NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
        guard event.type == .keyDown,
              event.modifierFlags.rawValue & indipendentFlagsMask == commandKeyFlags,
              event.charactersIgnoringModifiers?.lowercased() == "c" else {
            return false
        }
        return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
    }
}
