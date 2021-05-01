//
//  WidgetsLoader.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation
import PockKit

private let kApplicationSupportPockFolder: String = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Application Support/Pock"
private let kWidgetsPath: String = kApplicationSupportPockFolder + "/Widgets"

internal final class WidgetsLoader {

	/// Typealias
	typealias WidgetsLoaderHandler = ([PKWidgetInfo]) -> Void
	
	/// File manager
	private let fileManager = FileManager.default

	/// Data
	private static var loadedWidgets: [PKWidgetInfo] {
		return installedWidgets.filter({ $0.loaded == true })
	}
	
	/// List of installed widgets (loaded or not)
	public static var installedWidgets: [PKWidgetInfo] = []
	
	init() {
		/// Create support folders, if needed
		guard createSupportFoldersIfNeeded() else {
			AppController.shared.showMessagePanelWith(
				title: "error.title.default".localized,
				message: "error.message.cant_create_support_folders".localized,
				style: .critical
			)
			return
		}
	}

	/// Create support folders, if needed
	private func createSupportFoldersIfNeeded() -> Bool {
		return fileManager.createFolderIfNeeded(at: kApplicationSupportPockFolder) && fileManager.createFolderIfNeeded(at: kWidgetsPath)
	}
	
	/// Load installed widgets
	internal func loadInstalledWidgets(_ completion: @escaping WidgetsLoaderHandler) {
		let widgetURLs = fileManager.filesInFolder(kWidgetsPath, filter: {
			$0.contains(".pock") && !$0.contains("disabled") && !$0.contains("/")
		})
		var widgets: [PKWidgetInfo] = []
		for widgetFilePathURL in widgetURLs {
			guard let widget = loadWidgetAtURL(widgetFilePathURL) else {
				continue
			}
			widgets.append(widget)
		}
		completion(widgets)
	}
	
	/// Load single widget
	private func loadWidgetAtURL(_ url: URL) -> PKWidgetInfo? {
		do {
			let info = try PKWidgetInfo(path: url)
			if !WidgetsLoader.installedWidgets.contains(info) {
				WidgetsLoader.installedWidgets.append(info)
			}
			return info
		} catch {
			Roger.error(error.localizedDescription)
			return nil
		}
	}
	
	/// Unload all widgets
	internal static func unloadAllWidgets() {
		for widget in loadedWidgets {
			let bundle = Bundle(for: widget.principalClass)
			Roger.debug("[WidgetsLoader] unloading: \(widget.name)")
			bundle.unload()
		}
	}

}
