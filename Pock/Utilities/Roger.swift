//
//  Roger.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation

/// Override Swift's `print(_:)` function
public func print(_ data: Any) {
	#if DEBUG
	Swift.print(data)
	#endif
}

/// Lightweight and performance-driven loggin class
public class Roger {

	/// Log levels
	public enum Level: String {
		case debug = "[💬]"
		case info = "[ℹ️]"
		case error = "[⛔]"
	}

	/// Helpers
	private class func fileName(at path: String) -> String {
		let components = path.components(separatedBy: "/")
		return components.isEmpty ? "" : components.last!
	}

	/// Base
	private static func _baseLogString(level: Level, file: String = #file, function: String = #function, line: Int = #line, _ data: Any?) {
		let base = "\(level.rawValue)[\(fileName(at: file))][\(function)]:\(line)"
		guard let data = data else {
			print("\(base) -> `null`")
			return
		}
		print("\(base) -> \(data)")
	}

	/// Log debug message (💬)
	public static func debug(_ data: Any?, file: String = #file, function: String = #function, line: Int = #line) {
		_baseLogString(level: .debug, file: file, function: function, line: line, data)
	}

	/// Log info message (ℹ️)
	public static func info(_ data: Any?, file: String = #file, function: String = #function, line: Int = #line) {
		_baseLogString(level: .info, file: file, function: function, line: line, data)
	}

	/// Log error message (⛔)
	public static func error(_ data: Any?, file: String = #file, function: String = #function, line: Int = #line) {
		_baseLogString(level: .error, file: file, function: function, line: line, data)
	}

}
