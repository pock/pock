//
//  EonilFSEvents.swift
//  EonilFSEvents
//
//  Created by Hoon H. on 2016/10/02.
//
//

import Foundation


///
/// Simple access to file-system events.
///
/// - Note:
///     This is specifically designed for GUI apps.
///     Use only in main thread.
///     If you want to access all the options of "FSEvents",
///     use `EonilFSEvents` class directly.
///
public struct EonilFSEvents {
    public static func startWatching(paths: [String], for id: ObjectIdentifier, with handler: @escaping (EonilFSEventsEvent) -> ()) throws {
        assert(Thread.isMainThread)
        assert(watchers[id] == nil)
        // This is convenient wrapper for UI.
        // UI usually needs quicker response rather than maximum throughput.
        // Tuned for quickest response.
        // For non-UI code, I strongly recommend to instantiate `EonilFSEvents` yourself
        // with proper parameters.
        let s = try EonilFSEventStream(
            pathsToWatch: paths,
            sinceWhen: .now,
            latency: 0,
            flags: [.noDefer, .fileEvents],
            handler: handler)
        s.setDispatchQueue(DispatchQueue.main)
        try s.start()
        watchers[id] = s
    }
    public static func stopWatching(for id: ObjectIdentifier) {
        assert(Thread.isMainThread)
        assert(watchers[id] != nil)
        guard let s = watchers[id] else { return }
        s.stop()
        s.invalidate()
        watchers[id] = nil
    }
}
private var watchers = [ObjectIdentifier: EonilFSEventStream]()
