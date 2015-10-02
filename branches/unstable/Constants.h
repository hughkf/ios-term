//
//  Constants.h
//  Terminal

#import <UIKit/UIKit.h>
#import <Foundation/NSString.h>
#import "svnversion.h"

#define MULTIPLE_TERMINALS      YES
#define MAXTERMINALS            4
#define NUM_TERMINAL_COLORS     5

#define TOGGLE_KEYBOARD_DELAY		 0.15

#define MENU_DELAY							 0.10 
#define MENU_TAP_DELAY           0.20
#define MENU_FADE_IN_TIME				 0.10
#define MENU_FADE_OUT_TIME			 0.10
#define MENU_SLOW_FADE_OUT_TIME	 1.00
#define MENU_BUTTON_HEIGHT      44.0f
#define MENU_BUTTON_WIDTH       60.0f
#define KEYBOARD_FADE_OUT_TIME   0.5f
#define KEYBOARD_FADE_IN_TIME    0.5f

#define DEFAULT_TERMINAL_WIDTH	80
#define DEFAULT_TERMINAL_HEIGHT	25

#define TERMINAL_LINE_SPACING   3.0f

// gesture pie zones

enum {
	ZONE_N,
	ZONE_NE,
	ZONE_E,
	ZONE_SE,
	ZONE_S,
	ZONE_SW,
	ZONE_W,
	ZONE_NW
};

#define MENU_BUTTON_DICT_KEYS 24

#define MENU_CMD      @"cmd"
#define MENU_TITLE    @"title"
#define MENU_SUBMENU  @"submenu"

struct StrCtrlMap 
{
  NSString * str; 
  unichar chars[6];
};

extern struct StrCtrlMap STRG_CTRL_MAP[];

extern NSString * ZONE_KEYS[];
extern NSString * DEFAULT_SWIPE_GESTURES[][2];
extern NSString * DEFAULT_MENU_BUTTONS[][MENU_BUTTON_DICT_KEYS];
