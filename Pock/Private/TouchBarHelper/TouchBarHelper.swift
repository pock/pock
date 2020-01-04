//
//  TouchBarHelper.swift
//  Pock
//
//  Created by Pierluigi Galdi on 04/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

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
    
    public static var isSystemControlStripVisible: Bool {
        let status = TouchBarHelper.readSystemControlStripStatus()
        return status?.isEmpty ?? false
    }
    
    public static func readSystemControlStripStatus() -> String? {
        return CommandLineHelper.execute(launchPath: "/usr/bin/defaults", arguments: ["read", "com.apple.touchbar.agent", "PresentationModeGlobal"])
    }
    
    public static func hideSystemControlStrip(_ completion: ((Bool) -> Void)? = nil) {
        CommandLineHelper.execute(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.touchbar.agent", "PresentationModeGlobal", "-string", "app"])
        TouchBarHelper.reloadTouchBarServer(completion)
    }
    
    public static func showSystemControlStrip(_ completion: ((Bool) -> Void)? = nil) {
        CommandLineHelper.execute(launchPath: "/usr/bin/defaults", arguments: ["delete", "com.apple.touchbar.agent", "PresentationModeGlobal"])
        TouchBarHelper.reloadTouchBarServer(completion)
    }
    
    public static func reloadTouchBarServer(_ completion: ((Bool) -> Void)? = nil) {
        let touchBarServerPid = _DFRGetServerPID().description
        let task = STPrivilegedTask(launchPath: "/bin/kill", arguments: [touchBarServerPid])
        guard let error = task?.launch() else {
            completion?(false)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [touchBarServerPid, error] in
            switch error {
            case errAuthorizationSuccess:
                completion?(true)
            default:
                completion?(false)
            }
            if !isProd {
                print("[TouchBarServer]: old_pid: `\(touchBarServerPid)` - new_pid: `\(_DFRGetServerPID().description)`")
            }
        })
    }
    
}
