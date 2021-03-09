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
	typealias WidgetsLoaderHandler = ([PKWidget.Type]) -> Void
	
	/// File manager
	private let fileManager = FileManager.default

	init() {
		/// Create support folders, if needed
		guard createSupportFoldersIfNeeded() else {
			// TODO: Show alert
			Roger.error("Can't create Pock's support folders.")
			return
		}
	}

	/// Create support folders, if needed
	private func createSupportFoldersIfNeeded() -> Bool {
		return fileManager.createFolderIfNeeded(at: kApplicationSupportPockFolder) && fileManager.createFolderIfNeeded(at: kWidgetsPath)
	}
	
	/// Load installed widgets
	internal func loadInstalledWidgets(_ completion: @escaping WidgetsLoaderHandler) {
		let widgetURLs = fileManager.filesInFolder(kWidgetsPath, filter: { $0.contains(".pock") && !$0.contains("disabled") && !$0.contains("/") })
		var widgets: [PKWidget.Type] = []
		for widgetFilePathURL in widgetURLs {
			guard let widget = loadWidgetAtURL(widgetFilePathURL) else {
				continue
			}
			widgets.append(widget)
		}
		completion(widgets)
	}
	
	/// Load single widget
	private func loadWidgetAtURL(_ url: URL) -> PKWidget.Type? {
		guard let widgetBundle = Bundle(url: url), let clss = widgetBundle.principalClass as? PKWidget.Type else {
			return nil
		}
		return clss
	}

}
