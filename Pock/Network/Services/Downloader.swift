//
//  Downloader.swift
//  Pock
//
//  Created by Pierluigi Galdi on 05/05/21.
//

import Foundation

// MARK: Error
internal enum DownloaderError: PockError {
	case invalidFileURL
	case responseError(reason: String?)
	case downloadError(reason: String?)
	case fileSystemError(reason: String?)
	var description: String {
		switch self {
		case .invalidFileURL:
			return "error.downloader.invalid-file-url".localized
		case .responseError(let reason):
			return "error.downloader.response-error".localized(reason ?? "")
		case .downloadError(let reason):
			return "error.downloader.download-error".localized(reason ?? "")
		case .fileSystemError(let reason):
			return "error.file-system-error".localized(reason ?? "")
		}
	}
}

internal class Downloader: NSObject, URLSessionTaskDelegate, URLSessionDownloadDelegate {
	
	private let progress: (Double) -> Void
	private let completion: (URL?, DownloaderError?) -> Void
	
	private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
	private var downloadTask: URLSessionDownloadTask!
	
	@discardableResult
	init(url: URL, progress: @escaping (Double) -> Void, completion: @escaping (URL?, DownloaderError?) -> Void) {
		self.progress = progress
		self.completion = completion
		super.init()
		self.downloadTask = session.downloadTask(with: url)
		self.downloadTask.resume()
	}
	
	// MARK: Handle progress
	
	func urlSession(
		_ session: URLSession,
		downloadTask: URLSessionDownloadTask,
		didWriteData bytesWritten: Int64,
		totalBytesWritten: Int64,
		totalBytesExpectedToWrite: Int64
	) {
		if downloadTask == self.downloadTask {
			let calculatedProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
			progress(calculatedProgress)
		}
	}
	
	// MARK: Handle completion
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let response = downloadTask.response as? HTTPURLResponse else {
			completion(nil, .responseError(reason: nil))
			return
		}
		switch response.statusCode {
		case 200...299:
			break
		case 404:
			completion(nil, .invalidFileURL)
			return
		default:
			completion(nil, .responseError(reason: response.statusCode.description))
			return
		}
		guard FileManager.default.createFolderIfNeeded(at: kWidgetsTempPathURL.path) else {
			completion(nil, .fileSystemError(reason: "error.missing-widgets-temp-folder".localized))
			return
		}
		do {
			let destinationURL = kWidgetsTempPathURL.appendingPathComponent(location.lastPathComponent)
			try FileManager.default.moveItem(at: location, to: destinationURL)
			completion(destinationURL, nil)
		} catch {
			completion(nil, .downloadError(reason: error.localizedDescription))
		}
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let error = error {
			completion(nil, .downloadError(reason: error.localizedDescription))
		}
	}
	
}

// MARK: Default widgets downloader

internal class DefaultWidgetsDownloader {
	
	#if DEBUG
	private let defaultWidgetsURLString: String = "https://pock.dev/api/dev/defaults.php"
	#else
	private let defaultWidgetsURLString: String = "https://pock.dev/api/defaults.php"
	#endif
	
	// MARK: Fetch default widgets list
	
	internal func fetchDefaultWidgets(_ completion: @escaping ([String: URL], DownloaderError?) -> Void) {
		guard let url = URL(string: defaultWidgetsURLString + "?core=\(Updater.fullAppVersion)") else {
			completion([:], .invalidFileURL)
			return
		}
		let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			if let error = error {
				Roger.error(error)
				completion([:], .responseError(reason: error.localizedDescription))
				return
			}
			guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
				completion([:], .responseError(reason: "Invalid response code"))
				return
			}
			guard httpResponse.mimeType == "application/json", let data = data else {
				completion([:], .responseError(reason: "Invalid response data"))
				return
			}
			do {
				let list = try JSONDecoder().decode([String: URL].self, from: data)
				completion(list, nil)
			} catch {
				Roger.error(error)
				completion([:], .responseError(reason: "Invalid response data"))
			}
		}
		task.resume()
	}
	
}
