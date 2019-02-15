//
//  EonilFSEventsIllogicalErrorLog.swift
//  EonilFSEvents
//
//  Created by Hoon H. on 2016/10/02.
//
//

/// An error that is very unlikely to happen if this library code is properly written.
///
public struct EonilFSEventsIllogicalErrorLog {
    public var code: EonilFSEventsCriticalErrorCode
    public var message: String?
    init(code: EonilFSEventsCriticalErrorCode) {
        self.code = code
    }
    init(code: EonilFSEventsCriticalErrorCode, message: String) {
        self.code = code
        self.message = message
    }
    func cast() {
        EonilFSEventsIllogicalErrorLog.handler(self)
    }

    /// Can be called at any thread.
    public static var handler: (EonilFSEventsIllogicalErrorLog) -> () = { assert(false, "EonilFSEvents: \($0)") }
}

public enum EonilFSEventsCriticalErrorCode {
    case missingContextRawPointerValue
    case unexpectedPathValueType
    case unmatchedEventParameterCounts
}
