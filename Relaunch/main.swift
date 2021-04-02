//
//  main.swift
//  Relaunch
//
//  Created by Pierluigi Galdi on 20/03/21.
//

import AppKit

class Observer: NSObject {
	let completion: (() -> Void)?
	init(_ completion: (() -> Void)?) {
		self.completion = completion
	}
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		completion?()
	}
}

autoreleasepool {
	let parentPID = atoi(ProcessInfo.processInfo.arguments[1])
	if let app = NSRunningApplication(processIdentifier: parentPID), let url = app.bundleURL {
		let listener = Observer {
			CFRunLoopStop(CFRunLoopGetCurrent())
		}
		app.addObserver(listener, forKeyPath: "isTerminated", options: .new, context: nil)
		app.terminate()
		CFRunLoopRun()
		app.removeObserver(listener, forKeyPath: "isTerminated", context: nil)
		do {
			try NSWorkspace.shared.launchApplication(at: url, options: .default, configuration: [:])
			NSLog("[Pock]: Pock relaunched successfully!")
		} catch {
			NSLog("[Pock]: Can't relaunch Pock right now. Reason: \(error.localizedDescription)")
		}
	}
}
