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

internal final class WidgetsInstaller: NSDocument {

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
		
		case installDefault
		case installingDefault(_ progress: DefaultWidgetsInstallProgress)
		case installedDefault(_ errors: String?)
	}
	
	private lazy var manager: FileManager = FileManager.default
	
	// MARK: NSDocument
	
	override init() {
		// default initialiser
	}
	
	init(contentsOf url: URL, ofType typeName: String) throws {
		super.init()
		let widget = try PKWidgetInfo(path: url)
		installWidget(widget) { error in
			let controller = WidgetsInstallViewController()
			if let error = error {
				controller.state = .error(error)
			} else {
				controller.state = .installed(widget: widget)
			}
			AppController.shared.openController(controller)
		}
	}
	
	// MARK: Methods
	
	// MARK: Install local widget
	
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
	
	// MARK: Uninstall local widget
	
	internal func uninstallWidget(_ widget: PKWidgetInfo, _ completion: (PockError?) -> Void) {
		do {
			try manager.removeItem(at: URL(fileURLWithPath: widget.path.path))
			completion(nil)
		} catch {
			Roger.error(error)
			completion(Error.cantRemove(reason: error.localizedDescription))
		}
	}
	
	// MARK: Update local widget
	
	internal func updateWidget(_ widget: PKWidgetInfo, version: Version, progress: @escaping (Double) -> Void, completion: @escaping (PockError?) -> Void) {
		downloadWidget(
			at: version.link,
			name: widget.name,
			progress: { [progress] calculatedProgress in
				async { [calculatedProgress] in
					progress(calculatedProgress)
				}
			},
			completion: completion
		)
	}
	
	private func downloadWidget(at url: URL, name: String, progress: @escaping (Double) -> Void, completion: @escaping (PockError?) -> Void) {
		Downloader(
			url: url,
			progress: progress,
			completion: { locationURL, error in
				async { [weak self, name, completion, locationURL, error] in
					if let error = error {
						completion(error)
						return
					}
					guard let url = locationURL else {
						completion(Error.cantCopy(reason: "error.invalid-path".localized))
						return
					}
					self?.extractAndInstall(name, atLocation: url, completion)
				}
			}
		)
	}
	
	// MARK: Download default widgets
	
	typealias DefaultWidgetsInstallProgress = (name: String, progress: Double, processed: Int, total: Int)
	typealias DefaultWidgetsInstallCompletion = [String: PockError?]
	
	internal func installDefaultWidgets(progress: @escaping (DefaultWidgetsInstallProgress) -> Void, completion: @escaping (DefaultWidgetsInstallCompletion) -> Void) {
		DefaultWidgetsDownloader().fetchDefaultWidgets { list, error in
			if let error = error {
				completion(["all": error])
				return
			}
			let semaphore = DispatchSemaphore(value: 0)
			let total = list.count
			var processed: Int = 1
			var errors: [String: PockError?] = [:]
			for (bundleIdentifier, url) in list.sorted(by: { $0.value.lastPathComponent < $1.value.lastPathComponent }) {
				guard let nameSubstring = bundleIdentifier.split(separator: ".").last else {
					processed += 1
					continue
				}
				let name = String(nameSubstring)
				self.downloadWidget(
					at: url,
					name: name,
					progress: { calculatedProgress in
						async { [progress, name, total, processed, calculatedProgress] in
							progress((
								name: name,
								progress: calculatedProgress,
								processed: processed,
								total: total
							))
						}
					},
					completion: { [completion, name] error in
						defer {
							dsleep(0.75)
							semaphore.signal()
						}
						errors[name] = error
						if processed == total {
							completion(errors)
						}
						processed += 1
					}
				)
				semaphore.wait()
			}
		}
	}
	
	// MARK: Extract downloaded widget
	
	private func extractAndInstall(_ widgetName: String, atLocation location: URL, _ completion: (PockError?) -> Void) {
		let zipFileLocation = location.deletingLastPathComponent().appendingPathComponent(widgetName).appendingPathExtension("zip")
		defer {
			try? manager.removeItem(at: zipFileLocation)
		}
		do {
			try manager.moveItem(at: location, to: zipFileLocation)
			try Zip.unzipFile(zipFileLocation, destination: kWidgetsTempPathURL, overwrite: true, password: nil)
			try manager.removeItem(at: zipFileLocation)
			let unzippedLocation = kWidgetsTempPathURL.appendingPathComponent(widgetName).appendingPathExtension("pock")
			let newWidget = try PKWidgetInfo(path: unzippedLocation)
			if let oldWidget = WidgetsLoader.installedWidgets.first(where: {
				$0.bundleIdentifier.lowercased() == widgetName.lowercased() || $0.name.lowercased() == widgetName.lowercased()
			}) {
				uninstallWidget(oldWidget) { error in
					if let error = error {
						completion(error)
					} else {
						installWidget(newWidget, removeSource: true, completion)
					}
				}
			} else {
				installWidget(newWidget, removeSource: true, completion)
			}
		} catch {
			completion(Error.cantCopy(reason: error.localizedDescription))
		}
	}
	
}
