//
//  Menu.h
//  Terminal

#import <UIKit/UIKit.h>
#import <UIKit/UIPopup.h> 
#import "Constants.h"
#import "Tools.h"

@class Menu;

//_______________________________________________________________________________

@interface MenuItem : NSObject
{
  Menu      * menu;
  Menu      * submenu;
  NSString  * title;
  NSString  * command;
}

- (id)  initWithMenu:(Menu*)menu;

- (int)       index;
- (BOOL)      hasSubmenu;
- (Menu*)     menu;
- (Menu*)     submenu;
- (void)      setSubmenu:(Menu*)menu;
- (NSString*) title;
- (void)      setTitle:(NSString*)title;
- (NSString*) command;
- (void)      setCommand:(NSString*)command;

- (NSDictionary*) getDict;

@end

//_______________________________________________________________________________

@interface Menu : NSObject
{
  NSMutableArray * items;
  NSString * dot;
}

+ (Menu*) menuWithArray:(NSArray*)array;
+ (Menu*) menuWithItem:(MenuItem*)item;
+ (Menu*) create;

- (id)        init;
- (int)       indexOfItem:(MenuItem*)item;
- (MenuItem*) itemAtIndex:(int)index;
- (NSArray*)  items;
- (NSArray*)  getArray;
- (NSString*) dotStringWithCommand:(NSString*)command;

@end

//_______________________________________________________________________________

@interface MenuButton : UIThreePartButton
{
  MenuItem * item;
}

-(id) initWithFrame:(CGRect)frame;

- (NSString*) command;
- (NSString*) commandString;
- (MenuItem*) item;
- (void)      setItem:(MenuItem*)item;
- (void)      setCommandString:(NSString *)commandString;
- (void)      setTitle:(NSString *)title;
- (BOOL)      isMenuButton;
- (BOOL)      isNavigationButton;
- (Menu*)     submenu;
- (void)      update;

@end

//_______________________________________________________________________________

@interface MenuView : UIView
{
  id delegate;
  MenuButton * activeButton;
  NSMutableArray * history;
  
  CGPoint location;
	NSTimer * timer;
  
  BOOL tapMode;
  BOOL visible;
  BOOL showsEmptyButtons;
}

@property BOOL visible;

+ (MenuView*)	sharedInstance;

- (void) loadMenu;
- (void) popMenu;
- (void) pushMenu:(Menu*)menu;
- (void) loadMenu:(Menu*)menu;
- (void) showAtPoint:(CGPoint)p;
- (void) showAtPoint:(CGPoint)p delay:(float)delay;
- (void) fadeInAtPoint:(CGPoint)p;
- (void) fadeIn;
- (void) hide;
- (void) stopTimer;
- (void) setTapMode:(BOOL)tapMode;
- (void) hideSlow:(BOOL)slow;
- (id)   delegate;
- (void) setDelegate:(id)delegate;
- (void) setShowsEmptyButtons:(BOOL)aBool;
- (void) handleTrackingAt:(CGPoint)point;
- (NSString*) handleTrackingEnd;
- (MenuButton*) buttonAtIndex:(int)index; 
- (void) deselectButton:(MenuButton*)button;
- (void) selectButton:(MenuButton*)button;

@end
