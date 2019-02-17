//
//  OSDUIHelper.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

@objc enum OSDImage: CLongLong {
    /// From 1 to 28
    case brightness      = 1
    case volume          = 3
    case mute            = 4
}

@objc protocol OSDUIHelperProtocol {
    @objc func showImage(_ img: OSDImage, onDisplayID: CGDirectDisplayID, priority: CUnsignedInt, msecUntilFade: CUnsignedInt, withText: String?)
    @objc func showImage(_ img: OSDImage, onDisplayID: CGDirectDisplayID, priority: CUnsignedInt, msecUntilFade: CUnsignedInt, filledChiclets: CUnsignedInt, totalChiclets: CUnsignedInt, locked: Bool)
}

class DK_OSDUIHelper {
    class func showHUD(type: OSDImage, filled: CUnsignedInt, total: CUnsignedInt = 16) {
        let conn = NSXPCConnection(machServiceName: "com.apple.OSDUIHelper", options: [])
        conn.remoteObjectInterface = NSXPCInterface(with: OSDUIHelperProtocol.self)
        conn.interruptionHandler = { print("Interrupted!") }
        conn.invalidationHandler = { print("Invalidated!") }
        conn.resume()
        let target = conn.remoteObjectProxyWithErrorHandler { print("Failed: \($0)") }
        guard let helper = target as? OSDUIHelperProtocol else { fatalError("Wrong type: \(target)") }
        helper.showImage(type, onDisplayID: CGMainDisplayID(), priority: 0x1f4, msecUntilFade: 2000, filledChiclets: filled, totalChiclets: total, locked: false)
    }
}
