//
//  Updater.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/21.
//

import Foundation

// MARK: Error
internal enum UpdaterError: PockError {
	case invalidEndpointURL
	case responseError(reason: String?)
	case parsingError
	case invalidCoreVersion(minVersion: String)
	var description: String {
		switch self {
		case .invalidEndpointURL:
			return "error.updater.invalid-endpoint-url".localized
		case .responseError(let reason):
			return "error.updater.response-error".localized(reason ?? "error.unknown-server-error".localized)
		case .parsingError:
			return "error.updater.parsing-error".localized
		case .invalidCoreVersion(let minVersion):
			return "error.updater.invalid-core-version".localized(minVersion)
		}
	}
}

// MARK: Notification
extension NSNotification.Name {
	static var didFetchLatestVersions = NSNotification.Name("didFetchLatestVersions")
}

internal class Updater {
	
	typealias Error = UpdaterError
	
	public typealias WidgetVersion = (version: Version?, error: Error?)
	
	// MARK: Build info
	
	static var appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
	static var buildVersion: String? = {
		let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
		return build == "1" ? nil : build
	}()
	static var fullAppVersion: String = {
		guard let build = buildVersion else {
			return appVersion
		}
		return "\(appVersion)-\(build)"
	}()
	
	// MARK: Netowrk core-info
	
	#if DEBUG
	private let latestVersionURLString: String = "https://pock.dev/api/dev/latestVersions.json"
	#else
	private let latestVersionURLString: String = "https://pock.dev/api/latestVersions.json"
	#endif
	
	// MARK: Cache (?)
	static private(set) var cachedLatestReleases: LatestReleases?
	
	// MARK: Fetch latest versions
	
	internal func fetchLatestVersions(ignoreCache: Bool = false, _ completion: @escaping (LatestReleases?, Error?) -> Void) {
		guard let url = URL(string: latestVersionURLString) else {
			completion(nil, .invalidEndpointURL)
			return
		}
		if ignoreCache == false, let cached = Updater.cachedLatestReleases {
			completion(cached, nil)
			return
		}
		let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			if let error = error {
				Roger.error(error)
				completion(nil, .responseError(reason: error.localizedDescription))
				return
			}
			guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
				completion(nil, .responseError(reason: "Invalid response code"))
				return
			}
			guard httpResponse.mimeType == "application/json", let data = data else {
				completion(nil, .responseError(reason: "Invalid response data"))
				return
			}
			do {
				Updater.cachedLatestReleases = try JSONDecoder().decode(LatestReleases.self, from: data)
				completion(Updater.cachedLatestReleases, nil)
				NotificationCenter.default.post(name: .didFetchLatestVersions, object: nil)
			} catch {
				Roger.error(error)
				completion(nil, .parsingError)
			}
		}
		task.resume()
	}
	
	// MARK: Get newest version for given widget
	
	static func newVersion(for widget: PKWidgetInfo) -> WidgetVersion {
		guard let new = cachedLatestReleases?.widgets.first(where: { $0.key.lowercased() == widget.bundleIdentifier.lowercased() })?.value else {
			return (nil, nil)
		}
		if let coreMin = new.coreMin {
			if fullAppVersion < coreMin {
				return (nil, .invalidCoreVersion(minVersion: coreMin))
			}
		}
		return widget.fullVersion < new.name ? (new, nil) : (nil, nil)
	}
	
}
