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
    
    private static var pipeForSTDOUT = Pipe()
    private static var pipeForSTDERR = Pipe()
    
    public static func listenForSTDOUTEvents(_ handler: @escaping (String) -> Void) {
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipeForSTDOUT.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        pipeForSTDOUT.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            let str = String(data: data, encoding: .utf8) ?? "[stdout]: <Invalid-utf8 data of size: \(data.count)>\n"
            async { [str] in
                handler(str)
            }
        }
    }
    
    public static func listenForSTDERREvents(_ handler: @escaping (String) -> Void) {
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipeForSTDERR.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        pipeForSTDERR.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            let str = String(data: data, encoding: .utf8) ?? "[stderr]: <Invalid-utf8 data of size: \(data.count)>\n"
            async { [str] in
                handler(str)
            }
        }
    }

	/// Log levels
	public enum Level: String, CaseIterable {
		case debug = "[💬]"
		case info = "[ℹ️]"
		case error = "[⛔]"
	}
	
	/// Allowed levels
	public static var allowedLevels: [Level] = Level.allCases

	/// Helpers
	private class func fileName(at path: String) -> String {
		let components = path.components(separatedBy: "/")
		return components.isEmpty ? "" : components.last!
	}

	/// Base
	private static func _baseLogString(level: Level, file: String = #file, function: String = #function, line: Int = #line, _ data: Any?) {
		guard allowedLevels.contains(level) else {
			return
		}
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
