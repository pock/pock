//
//  InjectInstaller.m
//  Pock
//
//  Created by Pierluigi Galdi on 14/01/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InjectInstaller.h"

@implementation InjectInstaller

- (instancetype)init {
    self = [super init];
    if (self) {
        _listener = [[NSXPCListener alloc] initWithMachServiceName:kInjectInstallerBundleID];
        [_listener setDelegate:self];
    }
    return self;
}

- (void)run {
    NSLog(@"[Pock]: %s", __FUNCTION__);
    [self.listener resume];
    [[NSRunLoop currentRunLoop] run];
}

/// MARK: Protocols (install)

- (void)installInjectFramework:(NSString *)frameworkPath completionBlock:(void (^)(BOOL))completionBlock {
    NSLog(@"[Pock]: Installing %@ ...", frameworkPath);
    if (frameworkPath.length <= 0) {
        NotifyFailureAndReturn
    }
    BOOL ret = YES;
    NSString *installPath = [NSString stringWithFormat:@"%@/%@", kInjectFrameworkDirPath, kInjectFrameworkName];
    if (ret) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:installPath]) {
            ret = [[NSFileManager defaultManager] removeItemAtPath:installPath error:NULL];
        }
    }
    if (ret) {
        ret = [[NSFileManager defaultManager] copyItemAtPath:frameworkPath toPath:installPath error:NULL];
    }
    completionBlock(ret);
}

/// MARK: Delegates

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    assert(listener == self.listener);
    assert(newConnection);
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PockInjectInstallerProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    return YES;
}

@end
