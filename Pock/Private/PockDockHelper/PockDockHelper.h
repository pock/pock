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
@property(nonatomic) BOOL minimized;
- (CGWindowItem *)initWithID:(CGWindowID)wid pid:(pid_t)pid name:(NSString *)name preview:(NSImage *)preview minimized:(BOOL)minimized;
@end

@interface PockDockHelper : NSObject
@property (nonatomic, retain) NSDictionary *dockItems;

+ (PockDockHelper *)sharedInstance;
- (NSString *)getBadgeCountForItemWithName:(NSString *)name;
- (NSArray *)getWindowsOfApp:(pid_t)pid;
- (BOOL)windowIsFrontmost:(CGWindowID)wid forApp:(NSRunningApplication *)app;
- (void)minimizeWindowItem:(CGWindowItem *)item;
- (void)activateWindowItem:(CGWindowItem *)item in:(NSRunningApplication *)app;
@end
