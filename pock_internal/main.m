//
//  main.m
//  Pock
//
//  Created by Pierluigi Galdi on 13/01/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "CaptainHook.h"
#import "PockInjectConstants.h"

@interface PockInternal: NSObject
+ (instancetype)sharedInternal;
- (void)registerForNotification;
@end

__attribute__((constructor))
void pock_internalEntry() {
    
    /// Log
    NSLog(@"[Pock]: hello %@ (%d), dkbs in da house, bitches!", [[NSBundle mainBundle] bundleIdentifier], getpid());
    
    /// Init
    [[PockInternal sharedInternal] registerForNotification];
    
}

@implementation PockInternal

+ (instancetype)sharedInternal {
    static PockInternal *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PockInternal alloc] init];
    });
    return sharedInstance;
}

- (void)registerForNotification {

    /// Log
    NSLog(@"[Pock]: %s", __FUNCTION__);
    
    /// Register for notification
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(getBadgeLabel) name:NSWorkspaceDidActivateApplicationNotification object:nil];
}

- (void)getBadgeLabel {
    
    /// Get badge
    NSString *badgeLabel = [[NSApplication sharedApplication] dockTile].badgeLabel;
    NSString *bundleID   = [[NSBundle mainBundle] bundleIdentifier];
    
    /// Check if bundleID is NULL
    if (badgeLabel == NULL) {
        badgeLabel = @"0";
    }
    
    /// Log
    NSLog(@"[Pock]: %s [\"%@\"] for %@", __FUNCTION__, badgeLabel, bundleID);
    
    /// Read data to plist file
    NSMutableDictionary *dict = [self readDataFromPlist];
    
    /// Add record
    dict[bundleID] = badgeLabel;
    
    /// Write back to file
    BOOL success = [self writeDataToPlist:dict];
    
    /// Log
    NSLog(@"[Pock]: %s! Added [%@] for %@", success ? "Success" : "Failed", badgeLabel, bundleID);
    
}

- (NSString *)plistFilePath {
    return [NSString stringWithFormat:@"%@/%@", kPockBadgeLabelsPlistDir.stringByExpandingTildeInPath, kPockBadgeLabelsPlistName];
}

- (BOOL)plistDirExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:kPockBadgeLabelsPlistDir.stringByExpandingTildeInPath];
}

- (BOOL)plistFileExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self plistFilePath]];
}

- (NSMutableDictionary *)readDataFromPlist {
    
    /// Check if plist exists
    if (![self plistFileExists]) {
        return [[NSMutableDictionary alloc] init];
    }
    
    /// Read file
    NSMutableDictionary *plistDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self plistFilePath]];
    
    /// Return
    return plistDict;
}

- (BOOL)writeDataToPlist:(NSMutableDictionary *)dict {
    
    /// Check if file exist
    if (![self plistFileExists]) {
        /// Check if dir exist
        if (![self plistDirExists]) {
            /// Create dir
            [[NSFileManager defaultManager] createDirectoryAtPath:kPockBadgeLabelsPlistDir.stringByExpandingTildeInPath withIntermediateDirectories:FALSE attributes:nil error:nil];
        }
        /// Create plist file
        [[NSFileManager defaultManager] createFileAtPath:[self plistFilePath] contents:nil attributes:nil];
    }
    
    /// Return
    return [dict writeToFile:[self plistFilePath] atomically:TRUE];
    
}
@end
