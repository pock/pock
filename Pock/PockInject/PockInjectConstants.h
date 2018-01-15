//
//  PockInjectConstants.h
//  Pock
//
//  Created by Pierluigi Galdi on 13/01/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NotifySuccessAndReturn      completionBlock(YES); return;
#define NotifyFailureAndReturn      completionBlock(NO); return;

FOUNDATION_EXPORT NSString *const   kInjectInstallerBundleID;
FOUNDATION_EXPORT NSString *const   kInjectHelperBundleID;

FOUNDATION_EXPORT NSString *const   kInjectFrameworkDirPath;
FOUNDATION_EXPORT NSString *const   kInjectFrameworkName;

FOUNDATION_EXPORT NSString *const   kInjectInternalBundleName;

FOUNDATION_EXPORT NSString *const   kPockInternalRequestBadgeUpdate;
FOUNDATION_EXPORT NSString *const   kPockInternalUpdateBadge;

FOUNDATION_EXPORT NSString *const   kPockBadgeLabelsPlistDir;
FOUNDATION_EXPORT NSString *const   kPockBadgeLabelsPlistName;

@protocol PockInjectInstallerProtocol
@required
- (void)installInjectFramework:(NSString *)frameworkPath completionBlock:(void(^)(BOOL success))completionBlock;
@end

@protocol PockInjectHelperProtocol
@required
- (void)injectPlugin:(NSString *)pluginPath intoPID:(pid_t)pid forBundleID:(NSString *)bundleID completionBlock:(void(^)(BOOL success))completionBlock;
@end
