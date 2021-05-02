//
//  Collections+Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 02/05/21.
//

import Foundation

extension Collection where Element: Equatable {
	
	public func without(_ excluded: Element...) -> [Element] {
		return filter({ !excluded.contains($0) })
	}
	
}
