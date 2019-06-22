//
//  StatusItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class StatusItemView: PKView {
    weak var item: StatusItem?
    override func didTapHandler() {
        item?.action()
    }
}

protocol StatusItem: class {
    var enabled: Bool   { get }
    var title:   String { get }
    var view:    NSView { get }
    func action()
    func reload()
    func didLoad()
    func didUnload()
}

extension StatusItem {
    func didLoad() { /* ... */ }
}
