//
//  Settings.h
//  Terminal

#import <Foundation/Foundation.h>
#import "Constants.h"
#import "Color.h"

//_______________________________________________________________________________

@interface TerminalConfig : NSObject
{
  int width;
	int fontSize;
	float fontWidth;
	BOOL autosize;
		
  NSString * font;
  NSString * args;
  
  RGBAColor colors[NUM_TERMINAL_COLORS];
}

- (NSString*) fontDescription;

@property RGBAColor * colors;
@property BOOL autosize;
@property int width;
@property int fontSize;
@property float fontWidth;
@property (readwrite, copy) NSString * font;
@property (readwrite, copy) NSString * args;

@end

//_______________________________________________________________________________

@interface Settings : NSObject
{
	NSString * arguments;
	NSArray * terminalConfigs;
	NSArray * menu;
	RGBAColor gestureFrameColor;
	BOOL multipleTerminals;
  NSMutableDictionary * swipeGestures;
}

//_______________________________________________________________________________

@property BOOL multipleTerminals;

+ (Settings*) sharedInstance;

- (id) init;

- (void) registerDefaults;
- (void) readUserDefaults;
- (void) writeUserDefaults;

- (NSArray*) terminalConfigs;
- (void) setArguments: (NSString*)arguments;
- (NSString*) arguments;
- (NSArray*) menu;
- (NSDictionary*) swipeGestures;
- (void) setCommand:(NSString*)command forGesture:(NSString*)zone;
- (RGBAColor) gestureFrameColor;
- (RGBAColorRef) gestureFrameColorRef;

//_______________________________________________________________________________

@end
