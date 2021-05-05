//
//  WidgetInstaller.swift
//  Pock
//
//  Created by Pierluigi Galdi on 03/05/21.
//

import Foundation
import PockKit
import Zip

// MARK: Error
internal enum WidgetsInstallerError: PockError {
	case invalidBundle(reason: String?)
	case cantCopy(reason: String?)
	case cantRemove(reason: String?)
	var description: String {
		switch self {
		case let .invalidBundle(reason):
			return "error.invalid-bundle".localized(reason ?? "error.unknown".localized)
		case let .cantCopy(reason):
			return "error.cant-copy".localized(reason ?? "error.unknown".localized)
		case let .cantRemove(reason):
			return "error.cant-remove".localized(reason ?? "error.unknown".localized)
		}
	}
}

internal final class WidgetsInstaller {

	typealias Error = WidgetsInstallerError
	
	// MARK: State

	internal enum State {
		case dragdrop
		case remove(widget: PKWidgetInfo)
		case install(widget: PKWidgetInfo)
		case update(widget: PKWidgetInfo, version: Version)
		case removing(widget: PKWidgetInfo)
		case installing(widget: PKWidgetInfo)
		case downloading(widget: PKWidgetInfo, progress: Double)
		case removed(widget: PKWidgetInfo)
		case installed(widget: PKWidgetInfo)
		case updated(widget: PKWidgetInfo)
		case error(_ error: PockError)
	}
	
	private lazy var manager: FileManager = FileManager.default
	
	// MARK: Methods
	
	internal func installWidget(_ widget: PKWidgetInfo, removeSource: Bool = false, _ completion: (PockError?) -> Void) {
		do {
			let fromLocation = URL(fileURLWithPath: widget.path.path)
			let toLocation = kWidgetsPathURL.appendingPathComponent(widget.path.lastPathComponent)
			if removeSource {
				try manager.moveItem(at: fromLocation, to: toLocation)
			} else {
				try manager.copyItem(at: fromLocation, to: toLocation)
			}
			completion(nil)
		} catch {
			Roger.error(error)
			completion(Error.cantCopy(reason: error.localizedDescription))
		}
	}
	
	internal func uninstallWidget(_ widget: PKWidgetInfo, _ completion: (PockError?) -> Void) {
		do {
			try manager.removeItem(at: URL(fileURLWithPath: widget.path.path))
			completion(nil)
		} catch {
			Roger.error(error)
			completion(Error.cantRemove(reason: error.localizedDescription))
		}
	}
	
	internal func updateWidget(_ widget: PKWidgetInfo, version: Version, progress: @escaping (Double) -> Void, completion: @escaping (PockError?) -> Void) {
		Downloader(
			url: version.link,
			progress: { [progress] calculatedProgress in
				async { [calculatedProgress] in
					progress(calculatedProgress)
				}
			},
			completion: { locationURL, error in
				async { [weak self, widget, completion, locationURL, error] in
					if let error = error {
						completion(error)
						return
					}
					guard let url = locationURL else {
						completion(Error.cantCopy(reason: "error.invalid-path".localized))
						return
					}
					self?.extractAndInstall(widget, atLocation: url, completion)
				}
			}
		)
	}
	
	private func extractAndInstall(_ widget: PKWidgetInfo, atLocation location: URL, _ completion: (PockError?) -> Void) {
		let zipFileLocation = location.deletingLastPathComponent().appendingPathComponent(widget.name).appendingPathExtension("zip")
		defer {
			try? manager.removeItem(at: zipFileLocation)
		}
		do {
			try manager.moveItem(at: location, to: zipFileLocation)
			try Zip.unzipFile(zipFileLocation, destination: kWidgetsTempPathURL, overwrite: true, password: nil)
			try manager.removeItem(at: zipFileLocation)
			let unzippedLocation = kWidgetsTempPathURL.appendingPathComponent(widget.name).appendingPathExtension("pock")
			let newWidget = try PKWidgetInfo(path: unzippedLocation)
			uninstallWidget(widget) { error in
				if let error = error {
					completion(error)
				} else {
					installWidget(newWidget, removeSource: true, completion)
				}
			}
		} catch {
			completion(Error.cantCopy(reason: error.localizedDescription))
		}
	}
	
}
