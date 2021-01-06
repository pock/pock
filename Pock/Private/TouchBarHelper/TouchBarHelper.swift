//
//  TouchBarHelper.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import CoreFoundation

fileprivate let kPresentationModeGlobal  = "PresentationModeGlobal" as CFString
fileprivate let kModeApp 				 = "app" as CFString
fileprivate let kModeAppWithControlStrip = "appWithControlStrip" as CFString
fileprivate let kTouchBarAgentIdentifier = "com.apple.touchbar.agent" as CFString

fileprivate class CommandLineHelper {
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

public class TouchBarHelper {
    
    // MARK: Pock internal's helpers
    
    public static var isSystemControlStripVisible: Bool {
        let status = TouchBarHelper.readSystemControlStripStatus()
		return status?.lowercased.contains("controlstrip") == true
    }
    
    public static func readSystemControlStripStatus() -> NSString? {
		return CFPreferencesCopyAppValue(kPresentationModeGlobal, kTouchBarAgentIdentifier) as? NSString
    }
    
	private static func setTouchBarPresentationMode(to mode: CFString) -> Bool {
		let currentMode = readSystemControlStripStatus()?.copy() as? NSString
		CFPreferencesSetAppValue(kPresentationModeGlobal, mode, kTouchBarAgentIdentifier)
		let result = CFPreferencesAppSynchronize(kTouchBarAgentIdentifier)
		reloadTouchBarAgent()
		#if DEBUG
		print("Touch Bar Presentation mode changed: [\(result ? "success" : "error")] \(currentMode ?? "unknown") -> \(mode)")
		#endif
		return result
	}
	
    public static func hideSystemControlStrip(_ completion: ((Bool) -> Void)? = nil) {
		let result = setTouchBarPresentationMode(to: kModeApp)
		completion?(result)
    }
    
    public static func resetSystemControlStripToUserPreference(_ completion: ((Bool) -> Void)? = nil) {
		let result = setTouchBarPresentationMode(to: kModeAppWithControlStrip)
		completion?(result)
    }
    
	public static func reloadTouchBarAgent(_ completion: ((Bool) -> Void)? = nil) {
		let result = CommandLineHelper.execute(launchPath: "/usr/bin/pkill", arguments: ["ControlStrip"])
		completion?(result != nil)
	}
	
    public static func reloadTouchBarServer(_ completion: ((Bool) -> Void)? = nil) {
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
        async(after: 1.5) { [touchBarServerPid, error] in
            switch error {
            case errAuthorizationSuccess:
                completion?(true)
            default:
                completion?(false)
            }
            #if DEBUG
                NSLog("[TouchBarServer]: old_pid: `\(touchBarServerPid)` - new_pid: `\(_DFRGetServerPID().description)`")
            #endif
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
        return AppDelegate.default.navController
    }
    
}
