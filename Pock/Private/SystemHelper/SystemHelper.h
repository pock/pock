//
//  SystemHelper.h
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

extern void SACLockScreenImmediate(void);

@interface SystemHelper : NSObject
+ (void)lock;
+ (void)sleep;
@end
