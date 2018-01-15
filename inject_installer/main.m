//
//  main.m
//  inject_installer
//
//  Created by Pierluigi Galdi on 14/01/18.
//  Copyright (c) 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InjectInstaller.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        InjectInstaller *installer = [[InjectInstaller alloc] init];
        [installer run];
    }
    
    NSLog(@"[Pock]: %@ exits", [[NSBundle mainBundle] bundleIdentifier]);
    return 0;
}
