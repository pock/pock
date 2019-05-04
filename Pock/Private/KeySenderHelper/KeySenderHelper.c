//
//  KeySenderHelper.c
//  Pock
//
//  Created by Pierluigi Galdi on 04/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

#include "KeySenderHelper.h"
#include <IOKit/hidsystem/IOHIDLib.h>

static io_connect_t _driver(void) {
    static mach_port_t sEventDrvrRef = 0;
    mach_port_t masterPort, service, iter;
    if (!sEventDrvrRef) {
        kern_return_t kr = IOMasterPort(bootstrap_port, &masterPort);
        assert(KERN_SUCCESS == kr);
        kr = IOServiceGetMatchingServices(masterPort, IOServiceMatching(kIOHIDSystemClass), &iter);
        assert(KERN_SUCCESS == kr);
        service = IOIteratorNext(iter);
        assert(service);
        kr = IOServiceOpen(service, mach_task_self(), kIOHIDParamConnectType, &sEventDrvrRef);
        assert(KERN_SUCCESS == kr);
        IOObjectRelease(service);
        IOObjectRelease(iter);
    }
    return sEventDrvrRef;
}

void KeySenderPress(uint16_t keyCode, _Bool isAux) {
    NXEventData event = { 0 };
    if (isAux) {
        event.compound.subType   = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
        event.compound.misc.L[0] = (NX_KEYDOWN << 8) | (keyCode << 16);
    }else {
        event.key.keyCode      = keyCode;
    }
    kern_return_t ret = IOHIDPostEvent(_driver(), isAux ? NX_SYSDEFINED : NX_KEYDOWN, (IOGPoint){0}, &event, kNXEventDataVersion, 0, 0);
    if (KERN_SUCCESS != ret)
        return;
}

void KeySenderRelease(uint16_t keyCode, _Bool isAux) {
    NXEventData event = { 0 };
    if (isAux) {
        event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
        event.compound.misc.L[0] = (NX_KEYUP << 8) | (keyCode << 16);
    }else {
        event.key.keyCode = keyCode;
    }
    kern_return_t ret = IOHIDPostEvent(_driver(), isAux ? NX_SYSDEFINED : NX_KEYUP, (IOGPoint){0}, &event, kNXEventDataVersion, 0, 0);
    if (KERN_SUCCESS != ret)
        return;
}
