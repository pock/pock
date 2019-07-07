//
//  SystemHelper.m
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

#import "SystemHelper.h"

@implementation SystemHelper
+ (void)lock {
    SACLockScreenImmediate();
}
+ (void)sleep {
    /*io_registry_entry_t r = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if (r) {
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);
        IOObjectRelease(r);
    }*/
    MDSendAppleEventToSystemProcess(kAESleep);
}

// Thanks to: @skywinder
// Ref:       https://stackoverflow.com/a/26489672
OSStatus MDSendAppleEventToSystemProcess(AEEventID eventToSendID) {
    AEAddressDesc                    targetDesc;
    static const ProcessSerialNumber kPSNOfSystemProcess = {0, kSystemProcess};
    AppleEvent                       eventReply          = {typeNull, NULL};
    AppleEvent                       eventToSend         = {typeNull, NULL};
    OSStatus status = AECreateDesc(typeProcessSerialNumber, &kPSNOfSystemProcess, sizeof(kPSNOfSystemProcess), &targetDesc);
    if (status != noErr) return status;
    status = AECreateAppleEvent(kCoreEventClass, eventToSendID, &targetDesc, kAutoGenerateReturnID, kAnyTransactionID, &eventToSend);
    AEDisposeDesc(&targetDesc);
    if (status != noErr) return status;
    status = AESendMessage(&eventToSend, &eventReply,kAENormalPriority, kAEDefaultTimeout);
    AEDisposeDesc(&eventToSend);
    if (status != noErr) return status;
    AEDisposeDesc(&eventReply);
    return status;
}

@end
