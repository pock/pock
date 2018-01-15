//
//  InjectHelper.m
//  Pock
//
//  Created by Pierluigi Galdi on 13/01/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InjectHelper.h"
#import "mach_inject_bundle.h"

@implementation InjectHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        _listener = [[NSXPCListener alloc] initWithMachServiceName:kInjectHelperBundleID];
        [_listener setDelegate:self];
    }
    return self;
}

- (void)run {
    NSLog(@"[Pock]: %s", __FUNCTION__);
    [self.listener resume];
    [[NSRunLoop currentRunLoop] run];
}

/// MARK: Protocols (inject)

- (void)injectPlugin:(NSString *)pluginPath intoPID:(pid_t)pid forBundleID:(NSString *)bundleID completionBlock:(void (^)(BOOL))completionBlock {
    NSLog(@"[Pock]: Inject plugin: %@ into (id: %@, pid: %d)", pluginPath.lastPathComponent, bundleID, pid);
    if ((pid <= 0) || (pluginPath.length <= 0)) {
        NotifyFailureAndReturn
    }
    mach_error_t error = mach_inject_bundle_pid(pluginPath.fileSystemRepresentation, pid);
    NSLog(@"[Pock]: Injection error: %d", error);
    completionBlock(error == err_none);
}

/// MARK: Delegates

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    assert(listener == self.listener);
    assert(newConnection);
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PockInjectHelperProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    return YES;
}

@end
