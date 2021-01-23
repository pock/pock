//
//  PockApplication.m
//  Pock
//
//  Created by Pierluigi Galdi on 02/01/2021.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

#import "PockApplication.h"

@implementation PockApplication
- (void)_crashOnException:(NSException *)exception {
    if ([exception.debugDescription rangeOfString:@"NSFunctionRow"].location != NSNotFound) {
        NSLog(@"[PockApplication]: Avoid _crashOnException with override: %@", exception.debugDescription);
        return;
    } else {
        [super _crashOnException:exception];
    }
}
@end
