//
//  StatusItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

protocol StatusItem {
    var title:  String { get }
    var view:   NSView { get }
    func action()
    func reload()
}
