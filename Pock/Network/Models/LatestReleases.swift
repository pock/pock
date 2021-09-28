//
//  LatestReleases.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/21.
//

import Foundation

internal struct LatestReleases: Codable {
	let core: Version
	let widgets: [String: Version]
}
