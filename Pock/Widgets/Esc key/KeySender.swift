//  Thanks: https://github.com/brianmichel/ESCapey
//
//  ESCKeySender.swift
//  ESCapey-macOS
//
//  Created by Brian Michel on 10/25/16.
//  Copyright © 2016 Brian Michel. All rights reserved.
//
import Foundation

protocol KeySender {
    var keyCode: CGKeyCode { get }
    func send()
    func press()
    func release()
}

extension KeySender {
    func send() {
        self.press()
        self.release()
    }
    func press() {
        let downEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        downEvent?.post(tap: .cghidEventTap)
    }
    func release() {
        let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        upEvent?.post(tap: .cghidEventTap)
    }
}

struct ESCKeySender: KeySender {
    let keyCode: CGKeyCode = 53
}
