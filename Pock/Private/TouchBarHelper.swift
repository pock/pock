//  TouchBarHelper.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import CoreFoundation

private let kPresentationModeGlobal  = "PresentationModeGlobal"   as CFString
private let kTouchBarAgentIdentifier = "com.apple.touchbar.agent" as CFString

private class CommandLineHelper {
	@discardableResult
	static func execute(launchPath: String, arguments: [String]) -> String? {
		let task = Process()
		task.launchPath = launchPath
		task.arguments = arguments
		let pipe = Pipe()
		task.standardOutput = pipe
		task.launch()
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		let output = String(data: data, encoding: String.Encoding.utf8)
		return output
	}
}

public enum PresentationMode: String {
	case app,
		 appWithControlStrip,
		 fullControlStrip,
		 functionKeys,
		 workflows,
		 workflowsWithControlStrip,
		 spaces,
		 spacesWithControlStrip
	public var hasControlStrip: Bool {
		switch self {
		case .appWithControlStrip, .workflowsWithControlStrip, .spacesWithControlStrip:
			return true
		default:
			return false
		}
	}
	/// statics
	static let `default` = PresentationMode.appWithControlStrip
}

public class TouchBarHelper {

	// MARK: Pock internal's helpers

	public static var isSystemControlStripVisible: Bool {
		return TouchBarHelper.currentPresentationMode.hasControlStrip
	}

	public static var currentPresentationMode: PresentationMode {
		guard let value = (CFPreferencesCopyAppValue(kPresentationModeGlobal, kTouchBarAgentIdentifier) as? NSObject)?.copy(),
			  let mode  = value as? String else {
			return .default
		}
		return PresentationMode(rawValue: mode) ?? .default
	}

	@discardableResult
	internal static func setPresentationMode(to mode: PresentationMode) -> Bool {
		guard currentPresentationMode != mode else {
			Roger.debug("Touch Bar Presentation mode already setted to: \(mode)")
			return false
		}
		let currentMode = currentPresentationMode
		CFPreferencesSetAppValue(kPresentationModeGlobal, mode.rawValue as CFString, kTouchBarAgentIdentifier)
		let result = CFPreferencesAppSynchronize(kTouchBarAgentIdentifier)
		reloadTouchBarAgent()
		Roger.debug("Touch Bar Presentation mode changed: [\(result ? "success" : "error")] \(currentMode) -> \(mode)")
		return result
	}
	
	@objc public static func markTouchBarAsDimmed(_ dimmed: Bool) {
		NSFunctionRow.markActiveFunctionRows(asDimmed: dimmed)
	}
	
	@objc public static func hideCloseButtonIfNeeded() {
		if let view = NSFunctionRow._topLevelViews().first(where: {
			object_getClass($0) === NSClassFromString("NSFunctionRowBackgroundColorView")
		}) as? NSView,
		   let stackView = view.subviews.first(where: { $0 is NSStackView }) as? NSStackView,
		   let closeButton = stackView.subviews.first(where: { $0 is NSButton }) {
			closeButton.isHidden = true
		}
	}

	@objc public static func reloadTouchBarAgent(_ completion: ((Bool) -> Void)? = nil) {
		let result = CommandLineHelper.execute(launchPath: "/usr/bin/pkill", arguments: ["ControlStrip"])
		completion?(result != nil)
	}

	internal static func reloadTouchBarServer(_ completion: ((Bool) -> Void)? = nil) {
		let touchBarServerPid = _DFRGetServerPID().description
		var task = STPrivilegedTask(launchPath: "/bin/kill", arguments: [touchBarServerPid])
		defer {
			task?.terminate()
			task = nil
		}
		guard let error = task?.launch() else {
			completion?(false)
			return
		}
		async(after: 2.525) { [touchBarServerPid, error] in
			switch error {
			case errAuthorizationSuccess:
				completion?(true)
			default:
				completion?(false)
			}
			Roger.debug("[TouchBarServer]: old_pid: `\(touchBarServerPid)` - new_pid: `\(_DFRGetServerPID().description)`")
		}
	}

	// MARK: NSTouchBar helpers
	@objc public static func presentOnTop(_ touchBar: NSTouchBar?) {
		guard let touchBar = touchBar else {
			return
		}
		if #available (macOS 10.14, *) {
			NSTouchBar.presentSystemModalTouchBar(touchBar, placement: 1, systemTrayItemIdentifier: nil)
		} else {
			NSTouchBar.presentSystemModalFunctionBar(touchBar, placement: 1, systemTrayItemIdentifier: nil)
		}
	}

	@objc public static func dismissFromTop(_ touchBar: NSTouchBar?) {
		guard let touchBar = touchBar else {
			return
		}
		if #available (macOS 10.14, *) {
			NSTouchBar.dismissSystemModalTouchBar(touchBar)
		} else {
			NSTouchBar.dismissSystemModalFunctionBar(touchBar)
		}
	}

	@objc public static func minimizeFromTop(_ touchBar: NSTouchBar?) {
		guard let touchBar = touchBar else {
			return
		}
		if #available (macOS 10.14, *) {
			NSTouchBar.minimizeSystemModalTouchBar(touchBar)
		} else {
			NSTouchBar.minimizeSystemModalFunctionBar(touchBar)
		}
	}

	@objc public static func mainNavigationController() -> Any? {
		return AppController.shared.navigationController
	}
	
	@objc public static func swizzleFunctions() {
		NSFunctionRow.swizzleFunctionMarkActiveFunctionRows
		NSFunctionRow.swizzleFunctionCloseButtonPadding
	}

}

// MARK: Swizzle - markActiveFunctionRows
extension NSFunctionRow {
	
	@objc static func s_markActiveFunctionRowsAsDimmed(_ dimmed: Bool) {
		Roger.debug("[Pock]: Swizzled method: `NSFunctionRow.markActiveFunctionRowsAsDimmed` - [dimmed: \(dimmed)]")
		if dimmed {
			AppController.shared.tearDownTouchBar()
		} else {
			AppController.shared.prepareTouchBar()
		}
	}
	
	internal static let swizzleFunctionMarkActiveFunctionRows: Void = {
		let sel1 = #selector(NSFunctionRow.markActiveFunctionRows(asDimmed:))
		let sel2 = #selector(NSFunctionRow.s_markActiveFunctionRowsAsDimmed(_:))
		if let met1 = class_getClassMethod(NSFunctionRow.self, sel1), let met2 = class_getClassMethod(NSFunctionRow.self, sel2) {
			method_exchangeImplementations(met1, met2)
		}
	}()
	
}

// MARK: Swizzle - escapeKeyPaddingForCloseButton
extension NSFunctionRow {
	
	@objc func s_escapeKeyPaddingForCloseButton(_ isForCloseButton: Bool) -> Double {
		let original = self.s_escapeKeyPaddingForCloseButton(isForCloseButton)
		Roger.debug("[Pock]: Swizzled method: `_NSFunctionRow.escapeKeyPaddingForCloseButton` - [padding: \(original), isForCloseButton: \(isForCloseButton)]")
		async {
			TouchBarHelper.hideCloseButtonIfNeeded()
		}
		return 0
	}
	
	internal static let swizzleFunctionCloseButtonPadding: Void = {
		let sel1 = NSSelectorFromString("escapeKeyPaddingForCloseButton:")
		let sel2 = #selector(NSFunctionRow.s_escapeKeyPaddingForCloseButton(_:))
		if let met1 = class_getInstanceMethod(NSClassFromString("_NSFunctionRow"), sel1), let met2 = class_getInstanceMethod(NSFunctionRow.self, sel2) {
			method_exchangeImplementations(met1, met2)
		}
	}()
	
}
