//
// Menu.h
// Terminal

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIThreePartButton.h>
#import <UIKit/UIView.h>

#import "Constants.h"
#import "Tools.h"

@class Menu;

@interface MenuItem : NSObject
{
    Menu *menu;
    Menu *submenu;
    NSString *title;
    NSString *command;

    id delegate;
}

@property(nonatomic, readonly) Menu *menu;
@property(nonatomic, retain) Menu *submenu;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *command;
@property(nonatomic, copy) NSString *commandString;
@property(nonatomic, assign) id delegate;

- (id)initWithMenu:(Menu *)menu;

- (BOOL)hasSubmenu;
- (int)index;
- (NSDictionary *)getDict;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface Menu : NSObject
{
    NSMutableArray *items;
    NSString *dot;
}

@property(nonatomic, readonly) NSArray *items;

+ (Menu *)menu;
+ (Menu *)menuWithArray:(NSArray *)array;

- (id)init;
- (NSArray *)getArray;
- (int)indexOfItem:(MenuItem *)item;
- (MenuItem *)itemAtIndex:(int)index;
- (NSString *)dotStringWithCommand:(NSString *)command;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface MenuButton : UIThreePartButton
{
    MenuItem *item;
}

@property(nonatomic, retain) MenuItem *item;

- (BOOL)isMenuButton;
- (BOOL)isNavigationButton;
- (void)update;
- (void)menuItemChanged:(MenuItem *)menuItem;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface MenuView : UIView
{
    MenuButton *activeButton;
    NSMutableArray *history;

    CGPoint location;
    NSTimer *timer;

    BOOL tapMode;
    BOOL visible;
    BOOL showsEmptyButtons;

    id delegate;
}

@property(nonatomic) BOOL tapMode;
@property(nonatomic) BOOL visible;
@property(nonatomic) BOOL showsEmptyButtons;
@property(nonatomic, assign) id delegate;

+ (MenuView *)sharedInstance;

- (void)loadMenu;
- (void)loadMenu:(Menu *)menu;
- (void)pushMenu:(Menu *)menu;
- (void)popMenu;
- (MenuButton *)buttonAtIndex:(int)index;
- (void)selectButton:(MenuButton *)button;
- (void)deselectButton:(MenuButton *)button;
- (void)handleTrackingAt:(CGPoint)point;
- (NSString *)handleTrackingEnd;
- (void)stopTimer;
- (void)showAtPoint:(CGPoint)p;
- (void)showAtPoint:(CGPoint)p delay:(float)delay;
- (void)fadeIn;
- (void)fadeInAtPoint:(CGPoint)p;
- (void)hide;
- (void)hideSlow:(BOOL)slow;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
