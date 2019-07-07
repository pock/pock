//
//  PockDockHelper.h
//  Pock
//
//  Created by Pierluigi Galdi on 01/08/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

extern AXError _AXUIElementGetWindow(AXUIElementRef window, CGWindowID *windowID);

@interface CGWindowItem : NSObject
@property(nonatomic) CGWindowID wid;
@property(nonatomic) pid_t pid;
@property(nonatomic) NSString *name;
@property(nonatomic) NSImage *preview;
- (CGWindowItem *)initWithID:(CGWindowID)wid pid:(pid_t)pid name:(NSString *)name preview:(NSImage *)preview;
@end

@interface PockDockHelper : NSObject
+ (PockDockHelper *)sharedInstance;
- (NSString *)getBadgeCountForItemWithName:(NSString *)name;
- (NSArray *)getWindowsOfAppWithPid:(pid_t)pid;
- (NSArray *)getWindowsOfApp:(pid_t)pid;
- (NSUInteger)windowsCountForApp:(NSRunningApplication *)app;
- (void)closeWindowWithID:(CGWindowID)wid forApp:(NSRunningApplication *)app;
- (void)activateWindowWithID:(CGWindowID)wid forApp:(NSRunningApplication *)app;
@end
