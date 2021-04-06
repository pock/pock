//
//  String+Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 09/03/21.
//

import Foundation

extension String {

	/// Localized string for given key
	var localized: String {
		return NSLocalizedString(self, tableName: "Localisations", bundle: .main, value: self, comment: self)
	}
	
	/// Class name as string
	init(_ clss: AnyClass) {
		self.init()
		autoreleasepool(invoking: {
			let clssName = NSStringFromClass(clss)
			if let realClssName = clssName.split(separator: ".").last {
				self = String(realClssName)
			} else {
				self = clssName
			}
		})
	}

}
