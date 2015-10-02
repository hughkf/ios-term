//
//  Preferences.h
//  Terminal

#import <UIKit/UIKit.h>
#import <UIKit/UIFontChooser.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UISwitchControl.h>
#import "UINavigationController.h"
#import <UIKit/UIPickerView.h>
#import <UIKit/UIPickerTable.h>
#import <UIKit/UIPickerTableCell.h>
#import "Color.h"

@class MobileTerminal;
@class TerminalConfig;
@class PreferencesGroup;
@class PieView;
@class PieButton;
@class MenuView;
@class MenuButton;

//_______________________________________________________________________________

@interface UIPickerTable (PickerTableExtensions)
@end

@interface UIPickerView (PickerViewExtensions)
@end

//_______________________________________________________________________________

@interface FontChooser : UIView
{
	id delegate;
	
	NSArray * fontNames;
	
	UIPickerView * fontPicker;
	UIPickerTable * pickerTable;
	
	NSString * selectedFont;
}

- (id) initWithFrame: (struct CGRect)rect;
- (void) selectFont: (NSString*)font;
- (void) createFontList;
- (void) setDelegate:(id)delegate;

@end

//_______________________________________________________________________________

@interface FontView : UIPreferencesTable
{
	FontChooser * fontChooser;
	UISliderControl * sizeSlider;
	UISliderControl * widthSlider;
}

-(FontChooser*) fontChooser;
-(id) initWithFrame:(CGRect)frame;
-(void) selectFont:(NSString*)font size:(int)size width:(float)width;
-(void) sizeSelected:(UISliderControl*)control;
-(void) widthSelected:(UISliderControl*)control;

@end

//_______________________________________________________________________________

@interface ColorTableCell : UIPreferencesTableCell
{
  RGBAColor color;
}

- (void) setColor:(RGBAColor)color;

@end

//_______________________________________________________________________________

@interface ColorButton : UIView
{
	RGBAColorRef colorRef;
}

- (id) initWithFrame:(CGRect)frame colorRef:(RGBAColorRef)c;
- (void) colorChanged:(NSArray*)colorValues;
- (void) setColorRef:(RGBAColorRef)colorRef;

@end

//_______________________________________________________________________________

@interface ColorView : UIPreferencesTable
{
  id delegate;
  
  RGBAColor color;
  
  ColorTableCell  * colorField;
  UISliderControl * redSlider;
  UISliderControl * greenSlider;
  UISliderControl * blueSlider;
  UISliderControl * alphaSlider;
}	

-(RGBAColor) color;
-(void) setColor:(RGBAColor)color;
-(void) setDelegate:(id)delegate;

@end

//_______________________________________________________________________________

@interface TerminalPreferences : UIPreferencesTable
{
	id                  fontButton;
  UITextField       * argumentField;
	UISliderControl   * widthSlider;
	UISliderControl   * autosizeSwitch;
	PreferencesGroup  * sizeGroup;
	UIPreferencesControlTableCell * widthCell;

  ColorButton * color0;
  ColorButton * color1;
  ColorButton * color2;
  ColorButton * color3;
  ColorButton * color4;

	TerminalConfig * config;
	int							 terminalIndex;
}

-(void) fontChanged;
-(id) initWithFrame:(CGRect)frame;
-(void) setTerminalIndex:(int)terminal;
-(void) autosizeSwitched:(UISliderControl*)control;
-(void) widthSelected:(UISliderControl*)control;

@end

//_______________________________________________________________________________

@interface GestureTableCell : UIPreferencesTableCell
{
  PieView * pieView;
}

- (id) initWithFrame:(CGRect)frame;
- (float) getHeight;

@end

//_______________________________________________________________________________

@interface GesturePreferences : UIPreferencesTable
{
  PreferencesGroup  * menuGroup;
  PieButton         * editButton;
  UITextField       * commandField;
  PieView           * pieView; 
  
  int swipes;
}

- (id) initWithFrame:(CGRect)frame swipes:(int)swipes;
- (void) pieButtonPressed:(PieButton*)button;
- (void) update;
- (PieView*) pieView;

@end

//_______________________________________________________________________________

@interface MenuTableCell : UIPreferencesTableCell
{
  MenuView * menu;
}

- (id) initWithFrame:(CGRect)frame;
- (float) getHeight;

@end

//_______________________________________________________________________________

@interface MenuPreferences : UIPreferencesTable
{
  PreferencesGroup  * menuGroup;
  MenuButton        * editButton;
  UITextField       * titleField;
  UITextField       * commandField;
  UIPreferencesControlTableCell * submenuControl;
  UISliderControl   * submenuSwitch;
  UIPushButton      * openSubmenu;
  MenuView          * menuView; 
}

- (id) initWithFrame:(CGRect)frame;
- (void) menuButtonPressed:(MenuButton*)button;
- (void) selectButtonAtIndex:(int)index;
- (void) update;
- (MenuView*) menuView;

@end

//_______________________________________________________________________________

@interface PreferencesGroup : NSObject 
{
	UIPreferencesTableCell * title;
	NSMutableArray * cells;
	NSMutableArray * keys;
	float titleHeight;
	int tag;
}

+ (id) groupWithTitle:(NSString*) title icon:(UIImage*)icon;
- (id) initWithTitle:(NSString*) title icon:(UIImage*)icon;
- (void) addCell:(id)cell;
- (void) removeCell:(id)cell;
- (id) addSwitch:(NSString*)label;
- (id) addSwitch:(NSString*)label target:(id)target action:(SEL)action;
- (id) addSwitch:(NSString*)label on:(BOOL)on;
- (id) addSwitch:(NSString*)label on:(BOOL)on target:(id)target action:(SEL)action;
- (id) addIntValueSlider:(NSString*)label range:(NSRange)range target:(id)target action:(SEL)action;
- (id) addFloatValueSlider: (NSString*)label minValue:(float)minValue maxValue:(float)maxValue target:(id)target action:(SEL)action;
- (id) addPageButton:(NSString*)label;
- (id) addPageButton:(NSString*)label value:(NSString*)value;
- (id) addColorPageButton:(NSString*)label colorRef:(RGBAColorRef)color;
- (id) addValueField:(NSString*)label value:(NSString*)value;
- (id) addTextField:(NSString*)label value:(NSString*)value;
- (id) addColorField;

- (int) rows;
- (BOOL) boolValueForRow: (int) row;
- (UIPreferencesTableCell*) row: (int) row;
- (NSString*) stringValueForRow: (int) row;

@property (readwrite) float titleHeight;
@property (readonly) UIPreferencesTableCell * title;
@end

//_______________________________________________________________________________

@interface PreferencesGroups : NSObject 
{
	NSMutableArray * groups;
}

- (id) init;
- (void) addGroup: (PreferencesGroup*) group;
- (PreferencesGroup*) groupAtIndex: (int) index;
- (int) groups;

- (int) numberOfGroupsInPreferencesTable: (UIPreferencesTable*)table;
- (int) preferencesTable: (UIPreferencesTable*) table numberOfRowsInGroup: (int) group;
- (UIPreferencesTableCell*) preferencesTable: (UIPreferencesTable*)table cellForGroup: (int)group;
- (float) preferencesTable: (UIPreferencesTable*)table heightForRow: (int)row inGroup: (int)group withProposedHeight: (float)proposed;
- (UIPreferencesTableCell*) preferencesTable: (UIPreferencesTable*)table cellForRow: (int)row inGroup: (int)group;

@end

//_______________________________________________________________________________

@interface PreferencesController : UINavigationController 
{
	MobileTerminal			* application;
	
	UIPreferencesTable	* settingsView;
	UIView							* aboutView;
	FontView						* fontView;
	ColorView           * colorView;
  MenuPreferences     * menuView;
  GesturePreferences  * gestureView;
  GesturePreferences	* longSwipeView;
  GesturePreferences	* twoFingerSwipeView;
  
	TerminalPreferences				* terminalView;

	UIPreferencesTextTableCell * terminalButton1;
	UIPreferencesTextTableCell * terminalButton2;
	UIPreferencesTextTableCell * terminalButton3;
	UIPreferencesTextTableCell * terminalButton4;
		
	PreferencesGroup * terminalGroup;

	int terminalIndex;
}

+(PreferencesController*) sharedInstance;

-(id) init;
-(void) initViewStack;

-(FontView*) fontView;
-(ColorView*) colorView;
-(TerminalPreferences*) terminalView;
-(MenuPreferences*) menuView;
-(GesturePreferences*) gestureView;
-(GesturePreferences*) longSwipeView;
-(GesturePreferences*) twoFingerSwipeView;
-(UIPreferencesTable*) settingsView;

-(void) setFontSize:(int)size;
-(void) setFontWidth:(float)width;
-(void) setFont:(NSString*)font;

-(id) aboutView;

@end

