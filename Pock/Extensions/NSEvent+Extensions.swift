//
//  NSEvent+Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/01/22.
//

import Foundation

internal extension NSEvent.ModifierFlags {
    
    func keyEquivalentStrings() -> [String] {
        var strings = [String]()
        if contains(.control) {
            strings.append("⌃")
        }
        if contains(.option) {
            strings.append("⌥")
        }
        if contains(.shift) {
            strings.append("⇧")
        }
        if contains(.command) {
            strings.append("⌘")
        }
        return strings
    }
    
}
