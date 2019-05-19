//
//  PockWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 19/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

@objc (PockWidget) protocol PockWidget: class {
    var identifier:         NSTouchBarItem.Identifier   { get }
    var customizationLabel: String                      { get set }
    var view:               NSView!                     { get set }
    
    init()
    @objc optional func viewWillAppear()
    @objc optional func viewDidAppear()
    @objc optional func viewWillDisappear()
    @objc optional func viewDidDisappear()
}
