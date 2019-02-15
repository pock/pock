//
//  EonilFSEventStream.swift
//  FSEventStreamWrapper
//
//  Created by Hoon H. on 2016/10/02.
//
//

import Foundation

/// Replicate `FSEventStream`'s features and interface as close as possible in Swift-y interface.
/// Apple can provide official wrapper in future release, and the name of the future wrapper type
/// is likely to be `FSEventStream`. So this wrapper suffixes name with `~UnofficialWrapper` to avoid
/// potential future name conflict.
///
/// - TODO: Device watching support.
///
public final class EonilFSEventStream {
    // This must be a non-nil value if an instance of this class has been created successfully.
    fileprivate var rawref: FSEventStreamRef!
    private let handler: (EonilFSEventsEvent) -> ()

    /*
     *  FSEventStreamCreate()
     *
     *  Discussion:
     *    Creates a new FS event stream object with the given parameters.
     *    In order to start receiving callbacks you must also call
     *    FSEventStreamScheduleWithRunLoop() and FSEventStreamStart().
     *
     *  Parameters:
     *
     *    allocator:
     *      The CFAllocator to be used to allocate memory for the stream.
     *      Pass NULL or kCFAllocatorDefault to use the current default
     *      allocator.
     *
     *    callback:
     *      An FSEventStreamCallback which will be called when FS events
     *      occur.
     *
     *    context:
     *      A pointer to the FSEventStreamContext structure the client
     *      wants to associate with this stream.  Its fields are copied out
     *      into the stream itself so its memory can be released after the
     *      stream is created.  Passing NULL is allowed and has the same
     *      effect as passing a structure whose fields are all set to zero.
     *
     *    pathsToWatch:
     *      A CFArray of CFStringRefs, each specifying a path to a
     *      directory, signifying the root of a filesystem hierarchy to be
     *      watched for modifications.
     *
     *    sinceWhen:
     *      The service will supply events that have happened after the
     *      given event ID. To ask for events "since now" pass the constant
     *      kFSEventStreamEventIdSinceNow. Often, clients will supply the
     *      highest-numbered FSEventStreamEventId they have received in a
     *      callback, which they can obtain via the
     *      FSEventStreamGetLatestEventId() accessor. Do not pass zero for
     *      sinceWhen, unless you want to receive events for every
     *      directory modified since "the beginning of time" -- an unlikely
     *      scenario.
     *
     *    latency:
     *      The number of seconds the service should wait after hearing
     *      about an event from the kernel before passing it along to the
     *      client via its callback. Specifying a larger value may result
     *      in more effective temporal coalescing, resulting in fewer
     *      callbacks and greater overall efficiency.
     *
     *    flags:
     *      Flags that modify the behavior of the stream being created. See
     *      FSEventStreamCreateFlags.
     *
     *  Result:
     *    A valid FSEventStreamRef.
     *  
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    public init(pathsToWatch: [String], sinceWhen: EonilFSEventsEventID, latency: TimeInterval, flags: EonilFSEventsCreateFlags, handler: @escaping (EonilFSEventsEvent) -> ()) throws {
        // `CoreServices.FSEventStreamCallback` is C callback and follows
        // C convention. Which means it cannot capture any external value.
        let callback: CoreServices.FSEventStreamCallback = { (
            _ streamRef: ConstFSEventStreamRef,
            _ clientCallBackInfo: UnsafeMutableRawPointer?,
            _ numEvents: Int,
            _ eventPaths: UnsafeMutableRawPointer,
            _ eventFlags: UnsafePointer<FSEventStreamEventFlags>,
            _ eventIds: UnsafePointer<FSEventStreamEventId>) -> () in
            guard let clientCallBackInfo1 = clientCallBackInfo else {
                EonilFSEventsIllogicalErrorLog(code: .missingContextRawPointerValue).cast()
                return
            }
            let eventPaths1: CFArray = Unmanaged.fromOpaque(eventPaths).takeUnretainedValue()
            guard let eventPaths2 = eventPaths1 as NSArray as? [NSString] as [String]? else {
                EonilFSEventsIllogicalErrorLog(code: .unexpectedPathValueType, message: "Cannot convert `\(eventPaths1)` into [String].").cast()
                return
            }
            guard numEvents == eventPaths2.count else {
                EonilFSEventsIllogicalErrorLog(code: .unmatchedEventParameterCounts, message: "Event count is `\(numEvents)`, but path count is `\(eventPaths2.count)`").cast()
                return
            }
            let unmanagedPtr: Unmanaged<EonilFSEventStream> = Unmanaged.fromOpaque(clientCallBackInfo1)
            let self1 = unmanagedPtr.takeUnretainedValue()
            for i in 0..<numEvents {
                let eventPath = eventPaths2[i]
                let eventFlag = eventFlags[i]
                let eventFlag1 = EonilFSEventsEventFlags(rawValue: eventFlag)
                let eventId = eventIds[i]
                let eventId1 = EonilFSEventsEventID(rawValue: eventId)
                let event = EonilFSEventsEvent(path: eventPath,
                                                                flag: eventFlag1,
                                                                ID: eventId1)
                self1.handler(event)
            }
        }
        self.handler = handler
        let unmanagedPtr = Unmanaged.passUnretained(self)
        var context = FSEventStreamContext(version: 0,
                             info: unmanagedPtr.toOpaque(),
                             retain: nil,
                             release: nil,
                             copyDescription: nil)
        func getPtr<T>(value: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
            return value
        }
        // Get pointer to a value on stack.
        // Stream creation function will copy the value, so it's safe to keep it
        // on stack.
        let context1: UnsafeMutablePointer<FSEventStreamContext>? = getPtr(value: &context)
        let pathsToWatch1: CFArray = pathsToWatch as [NSString] as NSArray as CFArray
        let sinceWhen1: FSEventStreamEventId = sinceWhen.rawValue
        let latency1: CFTimeInterval = latency as CFTimeInterval
        // Always use CF types to avoid copying cost. But I am pretty sure that this
        // ultimately trigger copying inside of the system framework...
        let flags1: FSEventStreamCreateFlags = flags.union(.useCFTypes).rawValue
        guard let newRawref = FSEventStreamCreate(nil, callback, context1, pathsToWatch1, sinceWhen1, latency1, flags1) else {
            throw EonilFSEventsError(code: .cannotCreateStream)
        }
        rawref = newRawref
    }
    deinit {
        // `rawref` is a CFType, so will be deallocated automatically.
    }
}

/*
 *  Accessors
 */
extension EonilFSEventStream {
    /*
     *  FSEventStreamGetLatestEventId()
     *
     *  Discussion:
     *    Fetches the sinceWhen property of the stream.  Upon receiving an
     *    event (and just before invoking the client's callback) this
     *    attribute is updated to the highest-numbered event ID mentioned
     *    in the event.
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *  Result:
     *    The sinceWhen attribute of the stream.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */

    @available(macOS, introduced: 10.5)
    @available(iOS, introduced: 6.0)
    public func getLatestEventID() -> EonilFSEventsEventID {
        let eventId = FSEventStreamGetLatestEventId(rawref)
        let eventID1 = EonilFSEventsEventID(rawValue: eventId)
        return eventID1
    }


//    /*
//     *  FSEventStreamGetDeviceBeingWatched()
//     *
//     *  Discussion:
//     *    Fetches the dev_t supplied when the stream was created via
//     *    FSEventStreamCreateRelativeToDevice(), otherwise 0.
//     *
//     *  Parameters:
//     *
//     *    streamRef:
//     *      A valid stream.
//     *
//     *  Result:
//     *    The dev_t for a device-relative stream, otherwise 0.
//     *
//     *  Availability:
//     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
//     *    CarbonLib:        not available
//     *    Non-Carbon CFM:   not available
//     */
//    @available(macOS, introduced: 10.5)
//    @available(iOS, introduced: 6.0)
//    public func getDeviceBeingWatched() -> dev_t {
//        return FSEventStreamGetDeviceBeingWatched(rawref)
//    }

    /*
     *  FSEventStreamCopyPathsBeingWatched()
     *
     *  Discussion:
     *    Fetches the paths supplied when the stream was created via one of
     *    the FSEventStreamCreate...() functions.
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *  Result:
     *    A CFArray of CFStringRefs corresponding to those supplied when
     *    the stream was created. Ownership follows the Copy rule.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(macOS, introduced: 10.5)
    @available(iOS, introduced: 6.0)
    public func copyPathsBeingWatched() -> [String] {
        let ret = FSEventStreamCopyPathsBeingWatched(rawref)
        guard let paths = ret as NSArray as? [NSString] as [String]? else {
            EonilFSEventsIllogicalErrorLog(code: .unexpectedPathValueType, message: "Cannot convert retrieved object `\(ret)` into `[String]`.").cast()
            // Unrecoverable.
            fatalError()
        }
        return paths
    }

//    /*
//     *  FSEventsCopyUUIDForDevice()
//     *
//     *  Discussion:
//     *    Gets the UUID associated with a device, or NULL if not possible
//     *    (for example, on read-only device).  A (non-NULL) UUID uniquely
//     *    identifies a given stream of FSEvents.  If this (non-NULL) UUID
//     *    is different than one that you stored from a previous run then
//     *    the event stream is different (for example, because FSEvents were
//     *    purged, because the disk was erased, or because the event ID
//     *    counter wrapped around back to zero). A NULL return value
//     *    indicates that "historical" events are not available, i.e., you
//     *    should not supply a "sinceWhen" value to FSEventStreamCreate...()
//     *    other than kFSEventStreamEventIdSinceNow.
//     *
//     *  Parameters:
//     *
//     *    dev:
//     *      The dev_t of the device that you want to get the UUID for.
//     *
//     *  Result:
//     *    The UUID associated with the stream of events on this device, or
//     *    NULL if no UUID is available (for example, on a read-only
//     *    device).  The UUID is stored on the device itself and travels
//     *    with it even when the device is attached to different computers.
//     *    Ownership follows the Copy Rule.
//     *
//     *  Availability:
//     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
//     *    CarbonLib:        not available
//     *    Non-Carbon CFM:   not available
//     */
//    extern CF_RETURNS_RETAINED CFUUIDRef __nullable
//    FSEventsCopyUUIDForDevice(dev_t dev)                          __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_6_0);

//    /*
//     *  FSEventsGetLastEventIdForDeviceBeforeTime()
//     *
//     *  Discussion:
//     *    Gets the last event ID for the given device that was returned
//     *    before the given time.  This is conservative in the sense that if
//     *    you then use the returned event ID as the sinceWhen parameter of
//     *    FSEventStreamCreateRelativeToDevice() that you will not miss any
//     *    events that happened since that time.  On the other hand, you
//     *    might receive some (harmless) extra events. Beware: there are
//     *    things that can cause this to fail to be accurate. For example,
//     *    someone might change the system's clock (either backwards or
//     *    forwards).  Or an external drive might be used on different
//     *    systems without perfectly synchronized clocks.
//     *
//     *  Parameters:
//     *
//     *    dev:
//     *      The dev_t of the device.
//     *
//     *    time:
//     *      The time as a CFAbsoluteTime whose value is the number of
//     *      seconds since Jan 1, 1970 (i.e. a posix style time_t).
//     *
//     *  Result:
//     *    The last event ID for the given device that was returned before
//     *    the given time.
//     *
//     *  Availability:
//     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
//     *    CarbonLib:        not available
//     *    Non-Carbon CFM:   not available
//     */
//    extern FSEventStreamEventId
//    FSEventsGetLastEventIdForDeviceBeforeTime(
//    dev_t            dev,
//    CFAbsoluteTime   time)                                      __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_6_0);

//    /*
//     *  FSEventsPurgeEventsForDeviceUpToEventId()
//     *
//     *  Discussion:
//     *    Purges old events from the persistent per-volume database
//     *    maintained by the service. Can only be called by the root user.
//     *  
//     *  Parameters:
//     *    
//     *    dev:
//     *      The dev_t of the device.
//     *    
//     *    eventId:
//     *      The event ID.
//     *  
//     *  Result:
//     *    True if it succeeds, otherwise False if it fails.
//     *  
//     *  Availability:
//     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
//     *    CarbonLib:        not available
//     *    Non-Carbon CFM:   not available
//     */
//    extern Boolean 
//    FSEventsPurgeEventsForDeviceUpToEventId(
//    dev_t                  dev,
//    FSEventStreamEventId   eventId)                             __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_6_0);

}

/*
 *  ScheduleWithRunLoop, UnscheduleFromRunLoop, Invalidate
 */
extension EonilFSEventStream {
    /*
     *  FSEventStreamScheduleWithRunLoop()
     *
     *  Discussion:
     *    This function schedules the stream on the specified run loop,
     *    like CFRunLoopAddSource() does for a CFRunLoopSourceRef.  The
     *    caller is responsible for ensuring that the stream is scheduled
     *    on at least one run loop and that at least one of the run loops
     *    on which the stream is scheduled is being run. To start receiving
     *    events on the stream, call FSEventStreamStart(). To remove the
     *    stream from the run loops upon which it has been scheduled, call
     *    FSEventStreamUnscheduleFromRunLoop() or FSEventStreamInvalidate().
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *    runLoop:
     *      The run loop on which to schedule the stream.
     *
     *    runLoopMode:
     *      A run loop mode on which to schedule the stream.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    public func scheduleWithRunloop(runLoop: RunLoop, runLoopMode: RunLoop.Mode) {
        let runLoopMode1 = runLoopMode as CFString
        FSEventStreamScheduleWithRunLoop(rawref, runLoop.getCFRunLoop(), runLoopMode1)
    }

    /*
     *  FSEventStreamUnscheduleFromRunLoop()
     *
     *  Discussion:
     *    This function removes the stream from the specified run loop,
     *    like CFRunLoopRemoveSource() does for a CFRunLoopSourceRef.
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *    runLoop:
     *      The run loop from which to unschedule the stream.
     *
     *    runLoopMode:
     *      The run loop mode from which to unschedule the stream.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    public func unscheduleFromRunLoop(runLoop: RunLoop, runLoopMode: RunLoop.Mode) {
        let runLoopMode1 = runLoopMode as CFString
        FSEventStreamUnscheduleFromRunLoop(rawref, runLoop.getCFRunLoop(), runLoopMode1)
    }

    /*
     *  FSEventStreamSetDispatchQueue()
     *
     *  Discussion:
     *    This function schedules the stream on the specified dispatch
     *    queue. The caller is responsible for ensuring that the stream is
     *    scheduled on a dispatch queue and that the queue is started. If
     *    there is a problem scheduling the stream on the queue an error
     *    will be returned when you try to Start the stream. To start
     *    receiving events on the stream, call FSEventStreamStart(). To
     *    remove the stream from the queue on which it was scheduled, call
     *    FSEventStreamSetDispatchQueue() with a NULL queue parameter or
     *    call FSEventStreamInvalidate() which will do the same thing.
     *    Note: you must eventually call FSEventStreamInvalidate() and it
     *    is an error to call FSEventStreamInvalidate() without having the
     *    stream either scheduled on a runloop or a dispatch queue, so do
     *    not set the dispatch queue to NULL before calling
     *    FSEventStreamInvalidate().
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *    q:
     *      The dispatch queue to use to receive events (or NULL to to stop
     *      receiving events from the stream).
     *
     *  Availability:
     *    Mac OS X:         in version 10.6 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.6, *)
    public func setDispatchQueue(_ q: DispatchQueue?) {
        FSEventStreamSetDispatchQueue(rawref, q)
    }

    /*
     *  FSEventStreamInvalidate()
     *
     *  Discussion:
     *    Invalidates the stream, like CFRunLoopSourceInvalidate() does for
     *    a CFRunLoopSourceRef.  It will be unscheduled from any runloops
     *    or dispatch queues upon which it had been scheduled.
     *    FSEventStreamInvalidate() can only be called on the stream after
     *    you have called FSEventStreamScheduleWithRunLoop() or
     *    FSEventStreamSetDispatchQueue().
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    public func invalidate() {
        FSEventStreamInvalidate(rawref)
    }
}

/*
 *  Start, Flush, Stop
 */
extension EonilFSEventStream {
    /*
     *  FSEventStreamStart()
     *
     *  Discussion:
     *    Attempts to register with the FS Events service to receive events
     *    per the parameters in the stream. FSEventStreamStart() can only
     *    be called once the stream has been scheduled on at least one
     *    runloop, via FSEventStreamScheduleWithRunLoop(). Once started,
     *    the stream can be stopped via FSEventStreamStop().
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *  Result:
     *    True if it succeeds, otherwise False if it fails.  It ought to
     *    always succeed, but in the event it does not then your code
     *    should fall back to performing recursive scans of the directories
     *    of interest as appropriate.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    public func start() throws {
        switch FSEventStreamStart(rawref) {
        case false:
            throw EonilFSEventsError.init(code: .cannotStartStream)
        case true:
            return
        }
    }

    /*
     *  FSEventStreamFlushAsync()
     *
     *  Discussion:
     *    Asks the FS Events service to flush out any events that have
     *    occurred but have not yet been delivered, due to the latency
     *    parameter that was supplied when the stream was created.  This
     *    flushing occurs asynchronously -- do not expect the events to
     *    have already been delivered by the time this call returns.
     *    FSEventStreamFlushAsync() can only be called after the stream has
     *    been started, via FSEventStreamStart().
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *  Result:
     *    The largest event id of any event ever queued for this stream,
     *    otherwise zero if no events have been queued for this stream.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    public func flushAsync() -> EonilFSEventsEventID {
        let eventId = FSEventStreamFlushAsync(rawref)
        let eventId1 = EonilFSEventsEventID(rawValue: eventId)
        return eventId1
    }

    /*
     *  FSEventStreamFlushSync()
     *
     *  Discussion:
     *    Asks the FS Events service to flush out any events that have
     *    occurred but have not yet been delivered, due to the latency
     *    parameter that was supplied when the stream was created.  This
     *    flushing occurs synchronously -- by the time this call returns,
     *    your callback will have been invoked for every event that had
     *    already occurred at the time you made this call.
     *    FSEventStreamFlushSync() can only be called after the stream has
     *    been started, via FSEventStreamStart().
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    public func flushSync() {
        FSEventStreamFlushSync(rawref)
    }

    /*
     *  FSEventStreamStop()
     *
     *  Discussion:
     *    Unregisters with the FS Events service.  The client callback will
     *    not be called for this stream while it is stopped.
     *    FSEventStreamStop() can only be called if the stream has been
     *    started, via FSEventStreamStart(). Once stopped, the stream can
     *    be restarted via FSEventStreamStart(), at which point it will
     *    resume receiving events from where it left off ("sinceWhen").
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    public func stop() {
        FSEventStreamStop(rawref)
    }
}

/*
 *  Debugging
 */
extension EonilFSEventStream {
    /*
     *  FSEventStreamShow()
     *
     *  Discussion:
     *    Prints a description of the supplied stream to stderr. For
     *    debugging only.
     *
     *  Parameters:
     *
     *    streamRef:
     *      A valid stream.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    private func show() {
        FSEventStreamShow(rawref)
    }

    /*
     *  FSEventStreamCopyDescription()
     *
     *  Discussion:
     *    Returns a CFStringRef containing the description of the supplied
     *    stream. For debugging only.
     *
     *  Result:
     *    A CFStringRef containing the description of the supplied stream.
     *    Ownership follows the Copy rule.
     *
     *  Availability:
     *    Mac OS X:         in version 10.5 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.5, *)
    fileprivate func copyDescription() -> String {
        let desc = FSEventStreamCopyDescription(rawref)
        let desc1 = desc as String
        return desc1
    }

    /*
     * FSEventStreamSetExclusionPaths()
     *
     * Discussion:
     *    Sets directories to be filtered from the EventStream.
     *    A maximum of 8 directories maybe specified.
     *
     * Result:
     *    True if it succeeds, otherwise False if it fails.
     *
     * Availability:
     *    Mac OS X:         in version 10.9 and later in CoreServices.framework
     *    CarbonLib:        not available
     *    Non-Carbon CFM:   not available
     */
    @available(OSX 10.9, *)
    private func setExclusionPaths(_ pathsToExclude: [String]) -> Bool {
        let pathsToExclude1 = pathsToExclude as [NSString] as NSArray as CFArray
        return FSEventStreamSetExclusionPaths(rawref, pathsToExclude1)
    }
}
extension EonilFSEventStream: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return copyDescription()
    }
    public var debugDescription: String {
        return copyDescription()
    }
}


