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
	
	/// Localized string for given key with additional data
	func localized(_ args: CVarArg...) -> String {
		let localized = NSLocalizedString(self, tableName: "Localisations", bundle: .main, value: self, comment: self)
		return String(format: localized, arguments: args)
	}
    
    /// Compare two versions
    func isGreatherThan(_ version: String) -> Bool {
        return compare(version, options: .numeric) == .orderedDescending
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
