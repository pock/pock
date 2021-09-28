//
//  FileManager+Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation

extension FileManager {

	func fileExists(at path: String?, directory: Bool) -> Bool {
		guard let path = path else {
			return false
		}
		if !directory {
			return fileExists(atPath: path)
		}
		var directoryExists: ObjCBool = false
		fileExists(atPath: path, isDirectory: &directoryExists)
		return directoryExists.boolValue
	}

	func createFolderIfNeeded(at path: String?) -> Bool {
		guard let path = path else {
			return false
		}
		if !fileExists(at: path, directory: true) {
			do {
				try createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
			} catch {
				Roger.error(error)
				return false
			}
		}
		return true
	}
	
	func filesInFolder(_ path: String?, filter: (String) throws -> Bool) -> [URL] {
		guard let path = path else {
			return []
		}
		do {
			let list = try (enumerator(atPath: path)?.allObjects as? [String])?.filter(filter) ?? []
			return list.map({ URL(fileURLWithPath: "\(path)/\($0)") })
		} catch {
			Roger.error(error)
		}
		return []
	}

}
