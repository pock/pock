//
//  Version.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/21.
//

import Foundation

internal struct Version: Codable {
	let name: String
	let link: URL
	let changelog: String
	let coreMin: String?
    private enum CodingKeys : String, CodingKey {
        case name, link, changelog, coreMin = "core_min"
    }
}
