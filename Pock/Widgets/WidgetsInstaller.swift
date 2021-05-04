//
//  WidgetInstaller.swift
//  Pock
//
//  Created by Pierluigi Galdi on 03/05/21.
//

import Foundation
import PockKit

// MARK: Error
internal enum WidgetsInstallerError: CustomStringConvertible {
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
		case update(widget: PKWidgetInfo)
		case removing(widget: PKWidgetInfo)
		case installing(widget: PKWidgetInfo)
		case downloading(widget: PKWidgetInfo, progress: Double)
		case success(widget: PKWidgetInfo, removed: Bool)
		case error(_ error: Error)
	}
	
	private lazy var manager: FileManager = FileManager.default
	
	// MARK: Methods
	
	internal func installWidget(_ widget: PKWidgetInfo, _ completion: (Error?) -> Void) {
		do {
			try manager.copyItem(
				at: URL(fileURLWithPath: widget.path.path),
				to: kWidgetsPathURL.appendingPathComponent(widget.path.lastPathComponent)
			)
			completion(nil)
		} catch {
			Roger.error(error)
			completion(.cantCopy(reason: error.localizedDescription))
		}
	}
	
	internal func uninstallWidget(_ widget: PKWidgetInfo, _ completion: (Error?) -> Void) {
		do {
			try manager.removeItem(at: URL(fileURLWithPath: widget.path.path))
			completion(nil)
		} catch {
			Roger.error(error)
			completion(.cantRemove(reason: error.localizedDescription))
		}
	}
	
	internal func updateWidget(_ widget: PKWidgetInfo, progress: (Double) -> Void, completion: (Error?) -> Void) {
		// TODO: Implement
	}
	
}
