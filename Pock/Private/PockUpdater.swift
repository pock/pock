//
//  PockUpdater.swift
//  Pock
//
//  Created by Pierluigi Galdi on 11/01/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation

internal struct Version: Codable {
	let name: String
	let link: URL
}

internal struct LatestReleases: Codable {
	let core: Version
	let widgets: [String: Version]
}

internal class PockUpdater {
	
	/// Endpoint
	#if DEBUG
	private let latestVersionURLString: String = "https://pock.dev/api/dev/latestRelease.json"
	#else
	private let latestVersionURLString: String = "https://pock.dev/api/latestRelease.json"
	#endif
	
	/// Info
	internal static var appVersion: String {
		let base = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "???"
		guard let build = buildVersion else {
			return base
		}
		return "\(base)-\(build)"
	}
	internal static let buildVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as? String
	
	/// Singleton
	internal static let `default`: PockUpdater = PockUpdater()
	
	/// Data
	internal var latestReleases: LatestReleases?
	
	/// Fetch new versions
	internal func fetchNewVersions(ignoreCache: Bool = false, _ completion: ((LatestReleases?) -> Void)?) {
		guard let latestVersionsURL = URL(string: latestVersionURLString) else {
			completion?(nil)
			return
		}
		if ignoreCache == false, let cached = self.latestReleases {
			completion?(cached)
			return
		}
		async {
			let request = URLRequest(url: latestVersionsURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
			URLSession.shared.invalidateAndCancel()
			URLSession.shared.dataTask(with: request, completionHandler: { [weak self] data, response, error in
				defer {
					URLSession.shared.finishTasksAndInvalidate()
				}
				guard let data = data, let response = try? JSONDecoder().decode(LatestReleases.self, from: data) else {
					completion?(nil)
					return
				}
				self?.latestReleases = response
				completion?(response)
			}).resume()
		}
	}
	
}
