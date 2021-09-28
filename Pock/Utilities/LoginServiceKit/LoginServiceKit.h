//
//  LoginServiceKit.h
//  Pock
//
//  Created by Pierluigi Galdi on 12/05/21.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface LoginServiceKit: NSObject

@property (nonatomic, nullable) struct OpaqueLSSharedFileListRef* loginItems;

- (nullable LSSharedFileListItemRef)loginItemForBundle:(nonnull NSBundle *)bundle;
- (BOOL)existsLoginItemForBundle:(nonnull NSBundle *)bundle;
- (BOOL)addLoginItemForBundle:(nonnull NSBundle *)bundle;
- (BOOL)removeLoginItemForBundle:(nonnull NSBundle *)bundle;

@end
