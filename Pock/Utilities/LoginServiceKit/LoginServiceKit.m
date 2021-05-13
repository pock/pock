//
//  LoginServiceKit.m
//  Pock
//
//  Created by Pierluigi Galdi on 12/05/21.
//
//  Thanks to:
// 	@boyvanamstel https://gist.github.com/boyvanamstel/1409312
//

#import "LoginServiceKit.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation LoginServiceKit

- (instancetype)init {
	self = [super init];
	if (self) {
		self.loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
		LSSharedFileListAddObserver(self.loginItems, CFRunLoopGetMain(), (__bridge CFStringRef)NSDefaultRunLoopMode, LoginItemsChanged, (__bridge void*)self);
		NSLog(@"[Pock][LoginServiceKit]: initialized");
	}
	return self;
}

- (void)dealloc {
	LSSharedFileListRemoveObserver(self.loginItems, CFRunLoopGetMain(), (__bridge CFStringRef)NSDefaultRunLoopMode, LoginItemsChanged, (__bridge void*)self);
	CFRelease(self.loginItems);
	NSLog(@"[Pock][LoginServiceKit]: deallocated");
}

static void LoginItemsChanged(LSSharedFileListRef list, void *context) {
	NSObject* object = (__bridge NSObject*)context;
	[object willChangeValueForKey:@"launchAtLogin"];
	[object didChangeValueForKey:@"launchAtLogin"];
}

- (LSSharedFileListItemRef)loginItemForBundle:(NSBundle *)bundle {
	NSURL* bundleURL = [bundle bundleURL];
	if ([bundleURL.path length] == 0) {
		return nil;
	}
	if (self.loginItems) {
		NSArray* listSnapshot = CFBridgingRelease(LSSharedFileListCopySnapshot(self.loginItems, NULL));
		for (id item in listSnapshot) {
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
			CFURLRef itemRefURL = LSSharedFileListItemCopyResolvedURL(itemRef, 0, NULL);
			if (itemRefURL && CFEqual(itemRefURL, CFBridgingRetain(bundleURL))) {
				CFRetain(itemRef);
				CFRelease(itemRefURL);
				return itemRef;
			}
			if (itemRefURL != nil) CFRelease(itemRefURL);
		}
	}
	return nil;
}

- (BOOL)existsLoginItemForBundle:(NSBundle *)bundle {
	LSSharedFileListItemRef itemRef = [self loginItemForBundle:bundle];
	BOOL result = itemRef != nil;
	if (itemRef != nil) CFRelease(itemRef);
	return result;
}

- (BOOL)addLoginItemForBundle:(NSBundle *)bundle {
	NSURL* bundleURL = [bundle bundleURL];
	if (self.loginItems && [bundleURL.path length] == 0) {
		return false;
	}
	CFURLRef url = (__bridge CFURLRef)bundleURL;
	LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(self.loginItems, kLSSharedFileListItemBeforeFirst, NULL, NULL, url, NULL, NULL);
	if (itemRef) CFRelease(itemRef);
	CFRelease(url);
	return true;
}

- (BOOL)removeLoginItemForBundle:(NSBundle *)bundle {
	LSSharedFileListItemRef itemRef = [self loginItemForBundle:bundle];
	if (itemRef == nil) return false;
	LSSharedFileListItemRemove(self.loginItems, itemRef);
	if (itemRef != nil) CFRelease(itemRef);
	return true;
}

@end

#pragma clang diagnostic pop
