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
    if (cf != NULL)
        CFRelease(cf);
}

@implementation CGWindowItem
- (CGWindowItem *)initWithID:(CGWindowID)wid pid:(pid_t)pid name:(NSString *)name preview:(NSImage *)preview minimized:(BOOL)minimized {
    self.wid = wid;
    self.pid = pid;
    self.name = name;
    self.preview = preview;
    self.minimized = minimized;
    return self;
}
@end

@implementation PockDockHelper

+ (PockDockHelper *)sharedInstance {
    static PockDockHelper *sharedInstance = NULL;
    @synchronized(self) {
        if (sharedInstance == NULL)
            sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (__nullable CFTypeRef)getValueForKey:(_Nonnull CFStringRef)key in:(AXUIElementRef)element {
    CFTypeRef value;
    AXUIElementCopyAttributeValue(element, key, &value);
    return value;
}

//  Thanks to: @Minebomber
//  Ref:       https://stackoverflow.com/a/36115210
//
- (AXUIElementRef)copyAXUIElementFrom:(AXUIElementRef)theContainer role:(NSString *)theRole atIndex:(NSInteger)theIndex {
    NSArray *list = [(NSArray *)CFBridgingRelease([self getValueForKey:kAXChildrenAttribute in:theContainer]) copy];
    if (list == NULL) {
        return NULL;
    }
    AXUIElementRef aResultElement = NULL;
    NSUInteger anIndex = -1;
    __weak PockDockHelper *weakSelf = self;
    for (int i = 0; i < [list count]; i++) {
        CFTypeRef elem = CFBridgingRetain(list[i]);
        NSString *role = (NSString *)CFBridgingRelease([weakSelf getValueForKey:kAXRoleAttribute in:elem]);
        if (role && [role isEqualToString:theRole]) {
            anIndex++;
        }
        if (anIndex == theIndex) {
            aResultElement = elem;
            break;
        }else {
            SafeCFRelease(elem);
        }
    }
    list = NULL;
    return aResultElement;
}

//  Thanks to: @Minebomber
//  Ref:       https://stackoverflow.com/a/36115210
//
- (AXUIElementRef)getDockItemWithName:(NSString *)name {
    NSArray *anArray = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dock"];
    if (anArray.count == 0) {
        return NULL;
    }
    AXUIElementRef anAXDockApp = AXUIElementCreateApplication([[anArray objectAtIndex:0] processIdentifier]);
    AXUIElementRef aList = [self copyAXUIElementFrom:anAXDockApp role:@"AXList" atIndex:0];
    if (aList == NULL) {
        SafeCFRelease(anAXDockApp);
        return NULL;
    }
    NSArray *aChildren = [(NSArray *)CFBridgingRelease([self getValueForKey:kAXChildrenAttribute in:aList]) copy];
    if (aChildren == NULL) {
        SafeCFRelease(aList);
        SafeCFRelease(anAXDockApp);
        return NULL;
    }
    NSInteger itemIndex = -1;
    __weak PockDockHelper *weakSelf = self;
    for (int i = 0; i < [aChildren count]; i++) {
        CFTypeRef anElement = CFBridgingRetain(aChildren[i]);
        NSString *title = (NSString *)CFBridgingRelease([weakSelf getValueForKey:kAXTitleAttribute in:anElement]);
        SafeCFRelease(anElement);
        if ([title isEqualToString:name]) {
            itemIndex = i;
            break;
        }
    }
    if (itemIndex == -1) {
        SafeCFRelease(aList);
        SafeCFRelease(anAXDockApp);
        return NULL;
    }
    AXUIElementRef aReturnItem = [self copyAXUIElementFrom:aList role:@"AXDockItem" atIndex:itemIndex];
    SafeCFRelease(aList);
    SafeCFRelease(anAXDockApp);
    return aReturnItem;
}

- (NSString *)getBadgeCountForItemWithName:(NSString *)name {
    AXUIElementRef dockItem = [self getDockItemWithName:name];
    if (dockItem == NULL) {
        SafeCFRelease(dockItem);
        return NULL;
    }
    NSString *statusLabel = [(NSString *)CFBridgingRelease([self getValueForKey:kAXStatusLabelAttribute in:dockItem]) copy];
    SafeCFRelease(dockItem);
    return statusLabel;
}

// MARK: CGWindowID

- (NSArray *)getWindowsOfApp:(pid_t)pid {
    
    if (pid <= 0) { return NULL; }
    AXUIElementRef elementRef = AXUIElementCreateApplication(pid);
    
    // TODO: Need to fix a leak here
    NSArray *arr = [(NSArray *)CFBridgingRelease([self getValueForKey:kAXWindowsAttribute in:elementRef]) copy];
    SafeCFRelease(elementRef);
    if (arr == NULL) {
        return NULL;
    }
    
    NSMutableArray *returnable = [[NSMutableArray alloc] init];
    __weak PockDockHelper *weakSelf = self;
    
    for (int i = 0; i < [arr count]; i++) {
        CFTypeRef window = CFBridgingRetain(arr[i]);
        NSString *windowName = [(NSString *)CFBridgingRelease([weakSelf getValueForKey:kAXTitleAttribute in:window]) copy];
        if (windowName != NULL && windowName.length > 0) {
            CGWindowID windowId = 0;
            AXError error = _AXUIElementGetWindow(window, &windowId);
            CGWindowItem *item;
            if (error == kAXErrorSuccess && windowId > 0) {
                NSImage *windowImage = [weakSelf getScreenshotOfWindowId:[[NSNumber alloc] initWithUnsignedLong:windowId]];
                if (windowImage != NULL && windowImage.size.width > 1 && windowImage.size.height > 1) {
                    item = [[CGWindowItem alloc] initWithID:windowId pid:pid name:windowName preview:windowImage minimized:false];
                }else {
                    item = [[CGWindowItem alloc] initWithID:windowId pid:pid name:windowName preview:NULL minimized:true];
                }
            }
            if (item != NULL)
                [returnable addObject:item];
        }
        SafeCFRelease(window);
    }
    
    return returnable;
}

- (NSImage *)getScreenshotOfWindowId:(NSNumber *)wid {
    CGWindowListOption option = kCGWindowListOptionIncludingWindow;
    CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, option, wid.unsignedIntValue, kCGWindowImageDefault);
    if (windowImage == NULL) { return NULL; }
    Profile(windowImage);
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:windowImage];
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    CGImageRelease(windowImage);
    if (image == NULL || (image.size.width <= 1 && image.size.height <= 1)) { return NULL; }
    return image;
}

// MARK: AXUIElementRef

- (AXUIElementRef)windowForId:(CGWindowID)wid pid:(pid_t)pid {
    if (pid <= 0) { return NULL; }
    AXUIElementRef elementRef = AXUIElementCreateApplication(pid);
    NSArray *windows = [(NSArray *)CFBridgingRelease([self getValueForKey:kAXWindowsAttribute in:elementRef]) copy];
    SafeCFRelease(elementRef);
    if (windows == NULL) {
        return NULL;
    }
    AXUIElementRef result = NULL;
    for (NSObject *window in windows) {
        AXUIElementRef itemRef = (AXUIElementRef)CFBridgingRetain(window);
        CGWindowID winid;
        AXError err = _AXUIElementGetWindow(itemRef, &winid);
        if (err) continue;
        if (wid == winid) {
            result = itemRef;
        }else {
            SafeCFRelease(itemRef);
        }
    }
    return result;
}

- (BOOL)windowIsFrontmost:(CGWindowID)wid forApp:(NSRunningApplication *)app {
    AXUIElementRef itemRef = [self windowForId:wid pid:app.processIdentifier];
    if (itemRef) {
        CFBooleanRef isMain = [self getValueForKey:kAXMainAttribute in:itemRef];
        NSLog(@"Window for app: %@ is focused: %@", app.bundleIdentifier, isMain);
        BOOL returnable = isMain == kCFBooleanTrue;
        SafeCFRelease(isMain);
        SafeCFRelease(itemRef);
        return returnable;
    }
    return false;
}

- (void)minimizeWindowItem:(CGWindowItem *)item {
    AXUIElementRef itemRef = [self windowForId:item.wid pid:item.pid];
    if (itemRef) {
        AXUIElementRef buttonRef = [self getValueForKey:kAXMinimizeButtonAttribute in:itemRef];
        AXUIElementPerformAction(buttonRef, kAXPressAction);
        AXUIElementSetAttributeValue(itemRef, kAXMinimizedAttribute, kCFBooleanTrue);
        SafeCFRelease(buttonRef);
        SafeCFRelease(itemRef);
    }
}

- (void)activateWindowItem:(CGWindowItem *)item in:(NSRunningApplication *)app {
    AXUIElementRef itemRef = [self windowForId:item.wid pid:item.pid];
    if (itemRef) {
        AXUIElementPerformAction(itemRef, kAXRaiseAction);
        [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        AXUIElementSetAttributeValue(itemRef, kAXMinimizedAttribute, kCFBooleanFalse);
        SafeCFRelease(itemRef);
    }
}

@end
