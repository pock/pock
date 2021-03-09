//
//  ApplePrivate.h
//  Pock
//
//  Created by Pierluigi Galdi on 09/03/21.
//

#import <AppKit/AppKit.h>

// MARK: NSMenu
@interface NSMenuItem (Pock)
- (void)_setViewHandlesEvents:(BOOL)arg0;
@end


// MARK: NSTouchBarItem
@interface NSTouchBarItem (Pock)
+ (void)addSystemTrayItem:(nonnull NSTouchBarItem *)item;
@end


// MARK: NSCustomTouchBarItem
@interface NSCustomTouchBarItem (Pock)
- (nullable NSView *)viewForCustomizationPalette;
- (nullable NSView *)viewForCustomizationPreview;
- (CGFloat)preferredSizeForCustomizationPalette;
@end


// MARK: NSTouchBar
@interface NSTouchBar (Pock)
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
/* Common */
- (void)_purgeCacheIfNecessary;
- (nonnull NSArray *)items;
@end


// MARK: NSFunctionRow
@interface NSFunctionRow: NSObject
+ (struct CGRect)defaultFrameForType:(long long)arg1;
+ (nonnull NSArray *)_topLevelFunctionRowViews;
+ (nonnull NSArray *)activeFunctionRows;
+ (nonnull NSFunctionRow *)makeSystemFunctionRowForTouchBar:(nonnull NSTouchBar *)arg1 systemType:(long long)arg2;
+ (void)removeActiveFunctionRow:(nonnull NSFunctionRow *)arg1;
+ (void)addActiveFunctionRow:(nonnull NSFunctionRow *)arg1;
@end


// MARK: DFRFoundation
extern int _DFRGetServerPID(void);
extern int _DFRGetTouchBarAgentPID(void);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);
extern void DFRElementSetControlStripPresenceForIdentifier(_Nonnull NSTouchBarItemIdentifier, BOOL);
