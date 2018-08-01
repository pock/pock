//
//  PockDockHelper.h
//  Pock
//
//  Created by Pierluigi Galdi on 01/08/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PockDockHelper : NSObject
+ (PockDockHelper *)sharedInstance;
- (NSString *)getBadgeCountForItemWithName:(NSString *)name;
@end
