//
//  EventStream.swift
//  Witness
//
//  Created by Niels de Hoog on 23/09/15.
//  Copyright © 2015 Invisible Pixel. All rights reserved.
//

import Foundation

/**
* The type of event stream to be used. For more information, please refer to the File System Events Programming Guide: https://developer.apple.com/library/mac/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html#//apple_ref/doc/uid/TP40005289-CH4-SW6
*/

public enum StreamType {
    case hostBased // default
    case diskBased
}

class EventStream {
    let paths: [String]

    // use explicitly unwrapped optional so we can pass self as context to stream
    private var stream: FSEventStreamRef!
    private let changeHandler: FileEventHandler
    
    init(paths: [String], type: StreamType = .hostBased, flags: EventStreamCreateFlags, latency: TimeInterval, deviceToWatch: dev_t = 0, changeHandler: @escaping FileEventHandler) {
        self.paths = paths
        self.changeHandler = changeHandler
        
        func callBack(stream: ConstFSEventStreamRef, clientCallbackInfo: UnsafeMutableRawPointer?, numEvents: Int, eventPaths: UnsafeMutableRawPointer, eventFlags: UnsafePointer<FSEventStreamEventFlags>, eventIDs: UnsafePointer<FSEventStreamEventId>) {

            let eventStream = unsafeBitCast(clientCallbackInfo, to: EventStream.self)
            let paths = unsafeBitCast(eventPaths, to: NSArray.self)
            
            var events = [FileEvent]()
            for i in 0..<Int(numEvents) {
                let event = FileEvent(path: paths[i] as! String, flags: FileEventFlags(rawValue: eventFlags[i]))
                events.append(event)
            }
            
            eventStream.changeHandler(events)
        }
        
        var context = FSEventStreamContext()
        context.info = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        
        let combinedFlags = flags.union(.UseCFTypes)
        
        switch type {
        case .hostBased:
            stream = FSEventStreamCreate(nil, callBack, &context, paths as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency, combinedFlags.rawValue)
        case .diskBased:
            stream = FSEventStreamCreateRelativeToDevice(nil, callBack, &context, deviceToWatch, paths as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency, combinedFlags.rawValue)
        }
        
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
    }
    
    func flush() {
        FSEventStreamFlushSync(stream)
    }
    
    func flushAsync() {
        FSEventStreamFlushAsync(stream)
    }
    
    deinit {
        // stop stream
        FSEventStreamStop(stream)
        
        // unschedule from all run loops
        FSEventStreamInvalidate(stream)
        
        // release
        FSEventStreamRelease(stream)
    }
}

public struct EventStreamCreateFlags: OptionSet {
    public let rawValue: FSEventStreamCreateFlags
    public init(rawValue: FSEventStreamCreateFlags) { self.rawValue = rawValue }
    init(_ value: Int) { self.rawValue = FSEventStreamCreateFlags(value) }
    
    public static let None = EventStreamCreateFlags(kFSEventStreamCreateFlagNone)

    // setting the UseCFTypes flag has no consequences, because Witness will always enable it
    public static let UseCFTypes = EventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes)
    public static let NoDefer = EventStreamCreateFlags(kFSEventStreamCreateFlagNoDefer)
    public static let WatchRoot = EventStreamCreateFlags(kFSEventStreamCreateFlagWatchRoot)
    public static let IgnoreSelf = EventStreamCreateFlags(kFSEventStreamCreateFlagIgnoreSelf)
    public static let FileEvents = EventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
    public static let MarkSelf = EventStreamCreateFlags(kFSEventStreamCreateFlagMarkSelf)
}
