//  Thanks: https://github.com/brianmichel/ESCapey
//
//  ESCKeySender.swift
//  ESCapey-macOS
//
//  Created by Brian Michel on 10/25/16.
//  Copyright © 2016 Brian Michel. All rights reserved.
//
import Foundation

protocol KeySenderProtocol {
    var keyCode: Int32  { get }
    var isAux:   Bool   { get }
    func send()
    func press()
    func release()
}

struct KeySender: KeySenderProtocol {
    let keyCode: Int32
    let isAux:   Bool
    init(keyCode: Int32, isAux: Bool) {
        self.keyCode = keyCode
        self.isAux   = isAux
    }
    func send() {
        self.press()
        self.release()
    }
    func press() {
        KeySenderPress(UInt16(keyCode), isAux)
    }
    func release() {
        KeySenderRelease(UInt16(keyCode), isAux)
    }
}
