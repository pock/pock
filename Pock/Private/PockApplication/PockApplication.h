//
//  PockApplication.h
//  Pock
//
//  Created by Pierluigi Galdi on 02/01/2021.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSApplication (Pock)
- (void)_crashOnException:(NSException * _Nullable)exception;
@end

@interface PockApplication: NSApplication
@end
