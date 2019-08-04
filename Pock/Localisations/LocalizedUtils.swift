//
//  LocalizedUtils.swift
//  Pock
//
//  Created by Licardo on 2019/7/7.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: self)
    }
}
