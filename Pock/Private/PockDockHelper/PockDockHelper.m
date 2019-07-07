//
//  PockDockHelper.m
//  Pock
//
//  Created by Pierluigi Galdi on 01/08/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

#import "PockDockHelper.h"

#define kAXStatusLabelAttribute CFSTR("AXStatusLabel")
#define Profile(img) CFRelease(CGDataProviderCopyData(CGImageGetDataProvider(img)))

void SafeCFRelease(CFTypeRef cf) {
    if (cf) CFRelease(cf);
}

@implementation CGWindowItem
- (CGWindowItem *)initWithID:(CGWindowID)wid pid:(pid_t)pid name:(NSString *)name preview:(NSImage *)preview {
    self.wid = wid;
    self.pid = pid;
    self.name = name;
    self.preview = preview;
    return self;
}
@end

@interface PockDockHelper ()
@property (nonatomic, retain) NSMutableDictionary *windowPositions;
@end

@implementation PockDockHelper

+ (PockDockHelper *)sharedInstance {
    static PockDockHelper *sharedInstance = nil;
    @synchronized(self) {
        if (sharedInstance == nil)
            sharedInstance = [[self alloc] init];
        sharedInstance.windowPositions = [[NSMutableDictionary alloc] init];
    }
    return sharedInstance;
}

//  Thanks to: @Minebomber
//  Ref:       https://stackoverflow.com/a/36115210
//
- (AXUIElementRef)copyAXUIElementFrom:(AXUIElementRef)theContainer role:(CFStringRef)theRole atIndex:(NSInteger)theIndex {
    AXUIElementRef aResultElement = NULL;
    CFTypeRef aChildren;
    AXError anAXError = AXUIElementCopyAttributeValue(theContainer, kAXChildrenAttribute, &aChildren);
    if (anAXError == kAXErrorSuccess) {
        NSUInteger anIndex = -1;
        for (id anElement in (__bridge NSArray *)aChildren) {
            if (theRole) {
                CFTypeRef aRole;
                anAXError = AXUIElementCopyAttributeValue((__bridge AXUIElementRef)anElement, kAXRoleAttribute, &aRole);
                if (anAXError == kAXErrorSuccess) {
                    if (CFStringCompare(aRole, theRole, 0) == kCFCompareEqualTo)
                        anIndex++;
                    SafeCFRelease(aRole);
                }
            }
            else
                anIndex++;
            if (anIndex == theIndex) {
                aResultElement = (AXUIElementRef)CFRetain((__bridge CFTypeRef)(anElement));
                break;
            }
        }
        SafeCFRelease(aChildren);
    }
    return aResultElement;
}

//  Thanks to: @Minebomber
//  Ref:       https://stackoverflow.com/a/36115210
//
- (AXUIElementRef)getDockItemWithName:(NSString *)name {
    NSArray *anArray = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dock"];
    if (anArray.count == 0) return nil;
    AXUIElementRef anAXDockApp = AXUIElementCreateApplication([[anArray objectAtIndex:0] processIdentifier]);
    AXUIElementRef aList = [self copyAXUIElementFrom:anAXDockApp role:kAXListRole atIndex:0];
    if (aList == nil) return nil;
    CFTypeRef aChildren;
    AXUIElementCopyAttributeValue(aList, kAXChildrenAttribute, &aChildren);
    NSInteger itemIndex = -1;
    if (aChildren == nil) return nil;
    for (NSInteger i = 0; i < CFArrayGetCount(aChildren); i++) {
        AXUIElementRef anElement = CFArrayGetValueAtIndex(aChildren, i);
        CFTypeRef aResult;
        AXUIElementCopyAttributeValue(anElement, kAXTitleAttribute, &aResult);
        if ([(__bridge NSString *)aResult isEqualToString:name]) {
            itemIndex = i;
        }
        SafeCFRelease(aResult);
    }
    SafeCFRelease(aChildren);
    SafeCFRelease(anAXDockApp);
    if (itemIndex == -1) {
        SafeCFRelease(aList);
        return nil;
    }
    AXUIElementRef aReturnItem = [self copyAXUIElementFrom:aList role:kAXDockItemRole atIndex:itemIndex];
    if (aReturnItem == nil) {
        SafeCFRelease(aList);
        return nil;
    }
    SafeCFRelease(aList);
    return  aReturnItem;
}

- (NSString *)getBadgeCountForItemWithName:(NSString *)name {
    AXUIElementRef dockItem = [self getDockItemWithName:name];
    if (dockItem == nil) return nil;
    CFTypeRef aStatusLabel;
    AXUIElementCopyAttributeValue(dockItem, kAXStatusLabelAttribute, &aStatusLabel);
    SafeCFRelease(dockItem);
    NSString *statusLabel = (__bridge NSString *)aStatusLabel;
    SafeCFRelease(aStatusLabel);
    return statusLabel;
}

// MARK: CGWindowID

- (NSArray *)getWindowsOfAppWithPid:(pid_t)pid {
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    NSArray *arr = (NSArray *)CFBridgingRelease(windowList);
    NSMutableArray *returnable = [[NSMutableArray alloc] init];
    for (NSObject *window in arr) {
        NSString *pid_s = [NSString stringWithFormat:@"%ld", (long)pid];
        NSNumber *owner = (NSNumber *)[window valueForKey:@"kCGWindowOwnerPID"];
        if (![owner.stringValue isEqualToString:pid_s]) { continue; }
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[window valueForKey:@"kCGWindowBounds"], &bounds);
        if (bounds.size.width > 1 && bounds.size.height > 1) {
            [returnable addObject:window];
        }
    }
    return returnable;
}

- (NSArray *)getWindowsOfApp:(pid_t)pid {
    NSArray *arr = [self getWindowsOfAppWithPid:pid];
    NSMutableArray *returnable = [[NSMutableArray alloc] init];
    [arr enumerateObjectsUsingBlock:^(id  _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *windowId     = (NSNumber *)[window valueForKey:@"kCGWindowNumber"];
        NSString *windowName   = [self getTitleForWindow:window];
        NSImage *windowImage   = [self getScreenshotOfWindow:window];
        if (windowId != nil && windowId > 0 && windowName != nil && windowImage != nil) {
            CGWindowItem *item = [[CGWindowItem alloc] initWithID:windowId.intValue pid:pid name:windowName preview:windowImage];
            [returnable addObject:item];
        }
    }];
    return returnable;
}

- (NSImage *)getScreenshotOfWindow:(NSObject *)window {
    NSNumber *wid = (NSNumber *)[window valueForKey:@"kCGWindowNumber"];
    // Create an image from the passed in windowID with the single window option selected by the user.
    CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, wid.unsignedIntValue, kCGWindowImageDefault);
    Profile(windowImage);
    // Create a bitmap rep from the image...
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:windowImage];
    // Create an NSImage and add the bitmap rep to it...
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    CGImageRelease(windowImage);
    if (image == nil || (image.size.width <= 1 && image.size.height <= 1)) { return nil; }
    return image;
}

- (NSString *)getTitleForWindow:(NSObject *)window {
    NSString *title = (NSString *)[window valueForKey:@"kCGWindowName"];
    if (title == nil || [title length] == 0) { return nil; }
    return title;
}

- (NSUInteger)windowsCountForApp:(NSRunningApplication *)app {
    return [self getWindowsOfAppWithPid:app.processIdentifier].count;
}

- (NSString *)getTitleForWindowAtPosition:(int)position forApp:(NSRunningApplication *)app {
    NSArray *arr = [self getWindowsOfAppWithPid:app.processIdentifier];
    NSObject *window = [arr objectAtIndex:position];
    if (window == nil) { return nil; }
    return [self getTitleForWindow:window];
}

// MARK: AXUIElementRef

- (NSArray *)getWindowsRefOfAppWithPid:(pid_t)pid {
    if (pid <= 0) { return nil; }
    AXUIElementRef elementRef = AXUIElementCreateApplication(pid);
    CFMutableArrayRef windowArray = nil;
    AXUIElementCopyAttributeValue(elementRef, kAXWindowsAttribute, (CFTypeRef*)&windowArray);
    SafeCFRelease(elementRef);
    if (windowArray == nil) {
        return nil;
    }
    CFIndex nItems = CFArrayGetCount(windowArray);
    if (nItems < 1) {
        SafeCFRelease(windowArray);
        return nil;
    }
    return (__bridge NSMutableArray *)windowArray;
}

- (AXUIElementRef)windowForId:(CGWindowID)wid pid:(pid_t)pid {
    NSArray *windows = [self getWindowsRefOfAppWithPid:pid];
    AXUIElementRef result = nil;
    for (NSObject *window in windows) {
        AXUIElementRef itemRef = (__bridge AXUIElementRef)window;
        CGWindowID winid;
        AXError err = _AXUIElementGetWindow(itemRef, &winid);
        if (err) continue;
        if (wid == winid) {
            result = itemRef;
        }
    }
    return result;
}

- (id)getValueForKey:(_Nonnull CFStringRef)key in:(AXUIElementRef)element {
    AXUIElementRef value = nil;
    AXUIElementCopyAttributeValue(element, key, (CFTypeRef*)&value);
    return (id)CFBridgingRelease(value);
}

- (void)closeWindowWithID:(CGWindowID)wid forApp:(NSRunningApplication *)app {
    AXUIElementRef itemRef = [self windowForId:wid pid:app.processIdentifier];
    if (itemRef) {
        AXUIElementRef buttonRef = (__bridge AXUIElementRef)([self getValueForKey:kAXCloseButtonAttribute in:itemRef]);
        AXUIElementPerformAction(buttonRef, kAXPressAction);
    }
    SafeCFRelease(itemRef);
}

- (void)activateWindowWithID:(CGWindowID)wid forApp:(NSRunningApplication *)app {
    AXUIElementRef itemRef = [self windowForId:wid pid:app.processIdentifier];
    if (itemRef) {
        AXUIElementPerformAction(itemRef, kAXRaiseAction);
        [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        AXUIElementSetAttributeValue(itemRef, kAXMainWindowAttribute, kCFBooleanTrue);
    }
    SafeCFRelease(itemRef);
}

@end
