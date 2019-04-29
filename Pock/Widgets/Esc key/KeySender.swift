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
        press()
        release()
    }
    func press() {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        let downEvent   = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true)
        downEvent?.post(tap: .cgAnnotatedSessionEventTap)
    }
    func release() {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        let upEvent     = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false)
        upEvent?.post(tap: .cgAnnotatedSessionEventTap)
    }
}

struct ESCKeySender: KeySender {
    let keyCode: CGKeyCode = 53
}
