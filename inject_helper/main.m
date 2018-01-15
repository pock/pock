//
//  main.m
//  inject_helper
//
//  Created by Pierluigi Galdi on 13/01/18.
//  Copyright (c) 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InjectHelper.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        InjectHelper *helper = [[InjectHelper alloc] init];
        [helper run];
    }
    
    NSLog(@"[Pock]: %@ exits", [[NSBundle mainBundle] bundleIdentifier]);
    return 0;
}
