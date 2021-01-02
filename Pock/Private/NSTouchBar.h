//
//  TouchBar.h
//  TouchBarTest
//
//  Created by Alexsander Akers on 2/13/17.
//  Copyright © 2017 Alexsander Akers. All rights reserved.
//

#import <AppKit/AppKit.h>

extern int _DFRGetServerPID();
extern int _DFRGetTouchBarAgentPID();
extern void DFRElementSetControlStripPresenceForIdentifier(_Nonnull NSTouchBarItemIdentifier, BOOL);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

@interface NSApplication ()
- (void)_crashOnException:(_Nonnull id)exception;
@end

@interface NSTouchBar ()
/* macOS 10.13 */
+ (void)presentSystemModalFunctionBar:(nullable NSTouchBar *)touchBar placement:(long long)placement systemTrayItemIdentifier:(nullable NSTouchBarItemIdentifier)identifier;
+ (void)presentSystemModalFunctionBar:(nullable NSTouchBar *)touchBar systemTrayItemIdentifier:(nullable NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalFunctionBar:(nullable NSTouchBar *)touchBar;
+ (void)minimizeSystemModalFunctionBar:(nullable NSTouchBar *)touchBar;

/* macOS 10.14 */
+ (void)presentSystemModalTouchBar:(nullable NSTouchBar *)touchBar placement:(long long)placement systemTrayItemIdentifier:(nullable NSTouchBarItemIdentifier)identifier;
+ (void)presentSystemModalTouchBar:(nullable NSTouchBar *)touchBar systemTrayItemIdentifier:(nullable NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalTouchBar:(nullable NSTouchBar *)touchBar;
+ (void)minimizeSystemModalTouchBar:(nullable NSTouchBar *)touchBar;
@end

@interface NSTouchBarItem ()
+ (void)addSystemTrayItem:(nullable NSTouchBarItem *)item;
+ (void)removeSystemTrayItem:(nullable NSTouchBarItem *)item;
@end

@interface NSCustomTouchBarItem (Pock)
@property (readwrite, strong, nullable) __kindof NSView *view;
@property (readwrite, strong, nullable) __kindof NSViewController *viewController;
@property (readwrite, copy, null_resettable) NSString *customizationLabel;
@end

