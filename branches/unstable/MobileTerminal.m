// MobileTerminal.h
#define DEBUG_METHOD_TRACE    0

#include "MobileTerminal.h"
#include "ShellKeyboard.h"
#include "PTYTextView.h"
#include "SubProcess.h"
#include "VT100Terminal.h"
#include "VT100Screen.h"
#include "GestureView.h"
#include "PieView.h"
#include "Menu.h"
#include "Preferences.h"
#include "Settings.h"
#include "ColorMap.h"

#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/UIView-Geometry.h>
#import <LayerKit/LKAnimation.h>
#import <CoreGraphics/CoreGraphics.h>

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation MobileTerminal

@synthesize landscape, degrees, controlKeyMode;

static MobileTerminal * application;

//_______________________________________________________________________________

+ (MobileTerminal*) application
{
	return application;
}

//_______________________________________________________________________________

+ (Menu*) menu
{
	return [application menu];
}

//_______________________________________________________________________________

- (void) applicationDidFinishLaunching:(NSNotification*)unused
{
	log(@"applicationDidFinishLaunching");
	
	application = self;
	
	int i;
	
	settings = [[Settings sharedInstance] retain];
	[settings registerDefaults];
	[settings readUserDefaults];

  menu = [Menu menuWithArray:[settings menu]];
  
	activeTerminal = 0;
	
  controlKeyMode = NO;
  keyboardShown = YES;

	degrees = 0;
	landscape = NO;
	
	CGSize screenSize = [UIHardware mainScreenSize];
  CGRect frame = CGRectMake(0, 0, screenSize.width, screenSize.height);

	processes = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
  screens   = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
  terminals = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
	scrollers = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
	textviews = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
  	
	for (numTerminals = 0; numTerminals < ([settings multipleTerminals] ? MAXTERMINALS : 1); numTerminals++)
	{
		VT100Terminal * terminal = [[VT100Terminal alloc] init];
		VT100Screen   * screen   = [[VT100Screen alloc] initWithIdentifier: numTerminals];
		SubProcess    * process  = [[SubProcess alloc] initWithDelegate:self identifier: numTerminals];
		UIScroller    * scroller = [[UIScroller alloc] init];
		
		[screens   addObject: screen];
		[terminals addObject: terminal];
		[processes addObject: process];
		[scrollers addObject: scroller];
		
		[screen setTerminal:terminal];
		[terminal setScreen:screen];		
		
		PTYTextView * textview = [[PTYTextView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 244.0f)
																												 source: screen
																											 scroller: scroller
																										 identifier: numTerminals];		
		[textviews addObject:textview];
	}
	
  keyboardView = [[[ShellKeyboard alloc] initWithFrame:CGRectMake(0.0f, 244.0f, 320.0f, 460.0f-244.0f)] retain];
  [keyboardView setInputDelegate:self];

	CGRect gestureFrame = CGRectMake(0.0f, 0.0f, 240.0f, 250.0f);
  gestureView = [[GestureView alloc] initWithFrame:gestureFrame delegate:self];

  mainView = [[[UIView alloc] initWithFrame:frame] retain];
  [mainView setBackgroundColor:colorWithRGB(0,0,0)];
	for (i = 0; i < numTerminals; i++)
  {
    [[scrollers objectAtIndex:i] setBackgroundColor:[[ColorMap sharedInstance] colorForCode:BG_COLOR_CODE termid:i]];
		[mainView addSubview:[scrollers objectAtIndex:i]];
  }
  [mainView addSubview:keyboardView];	
  [mainView addSubview:[keyboardView inputView]];
  [mainView addSubview:gestureView];
	[mainView addSubview:[MenuView sharedInstance]];
	activeView = mainView;

	contentView = [[UITransitionView alloc] initWithFrame: frame];
	[contentView addSubview:mainView];
	
	window = [[UIWindow alloc] initWithFrame: frame];
	[window setContentView: contentView]; 
	[window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];
	[window retain];	
			
  // Shows momentarily and hides so the user knows its there
  [[MenuView sharedInstance] hideSlow:YES];

  // Input focus
  [[keyboardView inputView] becomeFirstResponder];
		
	if (numTerminals > 1)
	{
		for (i = numTerminals-1; i >= 0; i--)
		{
			[self setActiveTerminal:i];
		}
	}
	else
	{
		[self updateFrames:YES];
	}
		
	log(@"application initialized");
}

// Suspend/Resume: We have to hide then show again the keyboard view to get it
// to properly acheive focus on suspend and resume.

//_______________________________________________________________________________

- (void)applicationResume:(GSEvent *)event
{
  [mainView addSubview:keyboardView];
  
	if (!keyboardShown)
	{
    CGRect kbFrame = [self keyboardFrame];
		kbFrame.origin.y += kbFrame.size.height;
		[keyboardView setFrame:kbFrame];
		[keyboardView setAlpha:0.0f];		
  }  
	
	[mainView addSubview:[keyboardView inputView]];
	[mainView bringSubviewToFront:gestureView];
	[mainView bringSubviewToFront:[MenuView sharedInstance]];
	[[keyboardView inputView] becomeFirstResponder];
	
	[self setActiveTerminal:0];
	[self updateStatusBar];
}

//_______________________________________________________________________________

- (void)applicationSuspend:(GSEvent *)event
{
	BOOL shouldQuit;
	int i;
	shouldQuit = YES;
	
	[settings writeUserDefaults];
	
	for (i = 0; i < [processes count]; i++) {
		if ([ [processes objectAtIndex: i] isRunning]) {
			shouldQuit = NO;
			break;
		}
	}
	
  if (shouldQuit) {		
    exit(0);
  }

  if (activeView != mainView) // preferences active
    [self togglePreferences];
  
  [[keyboardView inputView] removeFromSuperview];
  [keyboardView removeFromSuperview];
	
	for (i = 0; i < MAXTERMINALS; i++)
		[self removeStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal%d", i]];
}

//_______________________________________________________________________________

- (void)applicationExited:(GSEvent *)event
{
	int i;
	
	[settings writeUserDefaults];
	
	for (i = 0; i < [processes count]; i++) {
		[[processes objectAtIndex: i] close];
	}	

	for (i = 0; i < MAXTERMINALS; i++)
		[self removeStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal%d", i]];
}

//_______________________________________________________________________________

// Process output from the shell and pass it to the screen
- (void)handleStreamOutput:(const char*)c length:(unsigned int)len identifier:(int)tid
{
	if (tid < 0 || tid >= [terminals count]) {
		return;
  }
	
  VT100Terminal* terminal = [terminals objectAtIndex: tid];
  VT100Screen* screen = [screens objectAtIndex: tid];
  	
  [terminal putStreamData:c length:len];

  // Now that we've got the raw data from the sub process, write it to the
  // terminal.  We get back tokens to display on the screen and pass the
  // update in the main thread.
  VT100TCC token;
  while((token = [terminal getNextToken]),
    token.type != VT100_WAIT && token.type != VT100CC_NULL) {
    // process token
    if (token.type != VT100_SKIP) {
      if (token.type == VT100_NOTSUPPORT) {
        NSLog(@"%s(%d):not support token", __FILE__ , __LINE__);
      } else {
        [screen putToken:token];
      }
    } else {
      NSLog(@"%s(%d):skip token", __FILE__ , __LINE__);
    }
  }
	
  if (tid == activeTerminal) 
	{
		[[self textView] performSelectorOnMainThread:@selector(updateAndScrollToEnd)
																			withObject:nil
																	 waitUntilDone:NO];
	}	
}

//_______________________________________________________________________________

// Process input from the keyboard
- (void)handleKeyPress:(unichar)c
{
  //log(@"c=0x%02x)", c);

  if (!controlKeyMode) 
	{
    if (c == 0x2022) 
		{
      controlKeyMode = YES;
      return;
    }
		else if (c == 0x0a) // LF from keyboard RETURN
		{
			c = 0x0d; // convert to CR
		}
  } 
	else 
	{    
    // was in ctrl key mode, got another key
    if (c < 0x60 && c > 0x40) 
		{
      // Uppercase
      c -= 0x40;
    } 
		else if (c < 0x7B && c > 0x60) 
		{
      // Lowercase
      c -= 0x60;
    }
    [self setControlKeyMode:NO];
  }
  // Not sure if this actually matches anything.  Maybe support high bits later?
  if ((c & 0xff00) != 0) 
	{
    NSLog(@"Unsupported unichar: %x", c);
    return;
  }
  char simple_char = (char)c;
	
  [[self activeProcess] write:&simple_char length:1];
}

//_______________________________________________________________________________

-(CGPoint) viewPointForWindowPoint:(CGPoint)point
{
	return [mainView convertPoint:point fromView:window];
}

//_______________________________________________________________________________

- (void)hideMenu
{
  [[MenuView sharedInstance] hide];
}

//_______________________________________________________________________________

- (void)showMenu:(CGPoint)point
{
  [[MenuView sharedInstance] showAtPoint:point];
}

//_______________________________________________________________________________

- (void)handleInputFromMenu:(NSString*)input
{
  if (input == nil) return;
  
  if ([input isEqualToString:@"[CTRL]"])
  {
    if (![[MobileTerminal application] controlKeyMode])
      [[MobileTerminal application] setControlKeyMode:YES];
  }
  else if ([input isEqualToString:@"[KEYB]"])
  {
    [[MobileTerminal application] toggleKeyboard];
  }
  else if ([input isEqualToString:@"[NEXT]"])
  {
    [[MobileTerminal application] nextTerminal];
  }
  else if ([input isEqualToString:@"[PREV]"])
  {
    [[MobileTerminal application] prevTerminal];
  }
  else if ([input isEqualToString:@"[CONF]"])
  {
    [[MobileTerminal application] togglePreferences];
  }
  else
  {
    [[self activeProcess] write:[input cString] length:[input length]];
  }    
}

//_______________________________________________________________________________

- (void)toggleKeyboard
{
	if (keyboardShown) 
	{
		keyboardShown = NO;
		
		[UIView beginAnimations:@"keyboardFadeOut"];
		[UIView setAnimationDuration: KEYBOARD_FADE_OUT_TIME];
		CGRect kbFrame = [self keyboardFrame];
		kbFrame.origin.y += kbFrame.size.height;
		[keyboardView setFrame:kbFrame];
		[keyboardView setAlpha:0.0f];		
		[UIView endAnimations];		
	}
	else
	{
		keyboardShown = YES;
		
		[UIView beginAnimations:@"keyboardFadeIn"];
		[UIView setAnimationDuration: KEYBOARD_FADE_OUT_TIME];
		[keyboardView setFrame:[self keyboardFrame]];
		[keyboardView setAlpha:1.0f];		
		[UIView endAnimations];		
	}
		
	[self updateFrames:NO];
}

//_______________________________________________________________________________

-(void) setControlKeyMode:(BOOL)mode
{
	controlKeyMode = mode;
	[[self textView] refreshCursorRow];
}

//_______________________________________________________________________________

- (void) statusBarMouseUp:(GSEvent*)event
{
	if (numTerminals > 1)
	{
		CGPoint pos = GSEventGetLocationInWindow(event);
		float width = landscape ? window.frame.size.height : window.frame.size.width;
		if (pos.x > width/2 && pos.x < width*3/4)
		{
			[self prevTerminal];
		}
		else if (pos.x > width*3/4)
		{
			[self nextTerminal];
		}
		else
		{
			if (activeView == mainView)
				[self togglePreferences];
		}
	}
	else
	{
		if (activeView == mainView)
			[self togglePreferences];
	}
}	

//_______________________________________________________________________________

- (void) deviceOrientationChanged: (GSEvent*)event 
{
	switch ([UIHardware deviceOrientation:YES])
	{
		case 1: [self setOrientation:  0]; break;
		case 3: [self setOrientation: 90]; break;
		case 4: [self setOrientation:-90]; break;
	}
}

//_______________________________________________________________________________
-(void) setOrientation:(int)angle
{
	if (degrees == angle || activeView != mainView) return;

	struct CGAffineTransform transEnd;
	switch(angle) 
	{
		case  90: transEnd = CGAffineTransformMake(0,  1, -1, 0, 0, 0); landscape = true;  break;
		case -90: transEnd = CGAffineTransformMake(0, -1,  1, 0, 0, 0); landscape = true;  break;
		case   0: transEnd = CGAffineTransformMake(1,  0,  0, 1, 0, 0); landscape = false; break;
		default:  return;
	}

	CGSize screenSize = [UIHardware mainScreenSize];
	CGRect contentBounds;

	if (landscape)
		contentBounds = CGRectMake(0, 0, screenSize.height, screenSize.width);
	else
		contentBounds = CGRectMake(0, 0, screenSize.width, screenSize.height);

	CGSize keybSize = [UIKeyboard defaultSizeForOrientation:(landscape ? 90 : 0)];
	CGRect keybRect = CGRectMake(0, contentBounds.size.height - keybSize.height, contentBounds.size.height, keybSize.height);	
	
	[UIView beginAnimations:@"screenRotation"];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
	[contentView setTransform:transEnd];
	[contentView setBounds:contentBounds];
	[keyboardView setFrame:keybRect];
	[UIView endAnimations];

	degrees = angle;
	[self updateStatusBar];
}

//_______________________________________________________________________________

-(void) updateStatusBar
{
	[self setStatusBarMode: [self statusBarMode]
						 orientation: degrees
								duration: 0.5 
								 fenceID: 0 
							 animation: 0];	
}

//_______________________________________________________________________________

- (void) updateColors
{
  int i, c;
  for (i = 0; i < numTerminals; i++)
  {
    TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:i];
    for (c = 0; c < NUM_TERMINAL_COLORS; c++)
      [[ColorMap sharedInstance] setTerminalColor:CGColorWithRGBAColor(config.colors[c]) atIndex:c termid:i];
    [[scrollers objectAtIndex:i] setBackgroundColor:[[ColorMap sharedInstance] colorForCode:BG_COLOR_CODE termid:i]];
    [[textviews objectAtIndex:i] setNeedsDisplay];
  }
  [self updateFrames:YES];
}

//_______________________________________________________________________________

-(CGRect) keyboardFrame
{
	CGSize keybSize = [UIKeyboard defaultSizeForOrientation:(landscape ? 90 : 0)];
	return CGRectMake(0, mainView.bounds.size.height - keybSize.height, 
											 mainView.bounds.size.width, keybSize.height);
}

//_______________________________________________________________________________

- (void) updateFrames:(BOOL)needsRefresh
{
	CGRect contentRect;
	CGRect textFrame;
	CGRect textScrollerFrame;
	CGRect gestureFrame;
	int columns, rows;
	
	//log(@"----------------- updateFrames needsRefresh %d", needsRefresh);

	struct CGSize size = [UIHardware mainScreenSize];
	CGSize keybSize = [UIKeyboard defaultSizeForOrientation:(landscape ? 90 : 0)];

	float statusBarHeight = [UIHardware statusBarHeight];
	
	if (landscape) contentRect = CGRectMake(0, statusBarHeight, size.height, size.width-statusBarHeight);
	else           contentRect = CGRectMake(0, statusBarHeight, size.width, size.height-statusBarHeight);

	[mainView setFrame:contentRect];
		
	TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:activeTerminal];

	float availableWidth = mainView.bounds.size.width;
	float availableHeight= mainView.bounds.size.height;
	
	if (keyboardShown) 
	{
		availableHeight -= keybSize.height;
	}
			
	float lineHeight = [config fontSize] + TERMINAL_LINE_SPACING;
	float charWidth  = [config fontSize]*[config fontWidth];
	
	rows = availableHeight / lineHeight;
	
	if ([config autosize])
	{
		columns = availableWidth / charWidth;
	}
	else
	{
		columns = [config width];
	}

	textFrame				  = CGRectMake(0.0f, 0.0f, columns * charWidth, rows * lineHeight);
	gestureFrame			= CGRectMake(0.0f, 0.0f, availableWidth-40.0f, availableHeight-(columns * charWidth > availableWidth ? 40.0f : 0));
	textScrollerFrame = CGRectMake(0.0f, 0.0f, availableWidth, availableHeight);

	[[self textView]     setFrame:textFrame];
	[[self textScroller] setFrame:textScrollerFrame];
	[[self textScroller] setContentSize:textFrame.size];
	[gestureView         setFrame:gestureFrame];
	[gestureView				 setNeedsDisplay];
	
	[[self activeProcess] setWidth:columns    height:rows];
	[[self activeScreen]  resizeWidth:columns height:rows];
		
	if (needsRefresh) 
	{
		[[self textView] refresh];	
		[[self textView] updateIfNecessary];
	}
}

//_______________________________________________________________________________

-(void) setActiveTerminal:(int)active
{
	[self setActiveTerminal:active direction:0];
}

//_______________________________________________________________________________

-(void) setActiveTerminal:(int)active direction:(int)direction
{
	[[self textView] willSlideOut];
		
	if (direction)
	{
		[UIView beginAnimations:@"slideOut"];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
		[(UIView*)[self textScroller] setTransform:CGAffineTransformMakeTranslation(-direction * [mainView frame].size.width, 0)];
		[UIView endAnimations];
	}
	else
	{
		[(UIView*)[self textScroller] setTransform:CGAffineTransformMakeTranslation(-[mainView frame].size.width,0)];
	}
	
	if (numTerminals > 1) [self removeStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal%d", activeTerminal]];
	
	activeTerminal = active;
	
	if (numTerminals > 1)	[self addStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal%d", activeTerminal] 
																removeOnAbnormalExit:YES];
	
	[mainView insertSubview:[self textScroller] below:keyboardView];

	if (direction)
	{
		[(UIView*)[self textScroller] setTransform:CGAffineTransformMakeTranslation(direction * [mainView frame].size.width,0)];
		
		[UIView beginAnimations:@"slideIn"];
		[(UIView*)[self textScroller] setTransform:CGAffineTransformMakeTranslation(0,0)];
		[UIView endAnimations];
	}
	else
	{
		[(UIView*)[self textScroller] setTransform:CGAffineTransformMakeTranslation(0,0)];
	}
		
	[self updateFrames:YES];
	
	[[self textView] willSlideIn];
}

//_______________________________________________________________________________

- (void) animationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context 
{
	if ([animationID isEqualToString:@"slideOut"])
	{
		int i;
		for (i = 0; i < numTerminals; i++)
		{
			if (i != activeTerminal) [[scrollers objectAtIndex:i] removeFromSuperview];
		}
	}
	else if ([animationID isEqualToString:@"screenRotation"])
	{
		[self updateFrames:YES];
		[keyboardView setFrame:[self keyboardFrame]];
	}
}

//_______________________________________________________________________________

-(void) prevTerminal
{
	if (numTerminals < 2) return;
	int active = activeTerminal - 1;
	if (active < 0) active = numTerminals-1;
	[self setActiveTerminal:active direction:-1];
}

//_______________________________________________________________________________

-(void) nextTerminal
{
	if (numTerminals < 2) return;
	int active = activeTerminal + 1;
	if (active >= numTerminals) active = 0;
	[self setActiveTerminal:active direction:1];
}

//_______________________________________________________________________________

-(void) createTerminals
{
  //log(@"createTerminals %d", MAXTERMINALS);
	for (numTerminals = 1; numTerminals < MAXTERMINALS; numTerminals++)
	{
    //log(@"create terminal");    
		VT100Terminal * terminal = [[VT100Terminal alloc] init];
    //log(@"create screen");    
		VT100Screen   * screen   = [[VT100Screen alloc] initWithIdentifier: numTerminals];
    //log(@"create process");    
		SubProcess    * process  = [[SubProcess alloc] initWithDelegate:self identifier: numTerminals];
    //log(@"process created");    
		UIScroller    * scroller = [[UIScroller alloc] init];

		[screens   addObject: screen];
		[terminals addObject: terminal];
		[processes addObject: process];
		[scrollers addObject: scroller];
		
		[screen setTerminal:terminal];
		[terminal setScreen:screen];		

    //log(@"create textview");    

		PTYTextView * textview = [[PTYTextView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 244.0f)
																												 source: screen
																											 scroller: scroller
																										 identifier: numTerminals];		
    //log(@"textview created");    
		[textviews addObject:textview];		
	}

	[self addStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal0"] removeOnAbnormalExit:YES];
  //log(@"terminals created");  
}

//_______________________________________________________________________________

-(void) destroyTerminals
{
	[self setActiveTerminal:0];
	
	[self removeStatusBarImageNamed:[NSString stringWithFormat:@"MobileTerminal0"]];
	
	for (numTerminals = MAXTERMINALS; numTerminals > 1; numTerminals--)
	{
		SubProcess * process = [processes lastObject];
		[process closeSession];
		[[textviews lastObject] removeFromSuperview];
		
		[screens   removeLastObject];
		[terminals removeLastObject];
		[processes removeLastObject];
		[scrollers removeLastObject];
		[textviews removeLastObject];
	}
}
	
//_______________________________________________________________________________

-(void) togglePreferences
{
	if (preferencesController == nil)
	{
		preferencesController = [PreferencesController sharedInstance];
		[preferencesController initViewStack];
	}
	
	if (activeView == mainView)
	{
		if (landscape) [self setOrientation:0];
		[contentView transition:0 toView:[preferencesController view]];
		activeView = [preferencesController view];
	}
	else
	{
		[contentView transition:0 toView:mainView];
		activeView = mainView;
		
		[settings writeUserDefaults];
    [self updateColors];
		[gestureView setNeedsDisplay];
		
		if (numTerminals > 1 && ![settings multipleTerminals])
		{
			[self destroyTerminals];
		}
		else if (numTerminals == 1 && [settings multipleTerminals])
		{
			[self createTerminals];
		}
	}
	
	LKAnimation * animation = [LKTransition animation];
	[animation performSelector:@selector(setType:) withObject:@"oglFlip"];
	[animation performSelector:@selector(setSubtype:) withObject:(activeView == mainView) ? @"fromRight" : @"fromLeft"];
	[animation performSelector:@selector(setTransitionFlags:) withObject:[NSNumber numberWithInt:3]];
	[animation setTimingFunction: [LKTimingFunction functionWithName: @"easeInEaseOut"]];
	//[animation setFillMode: @"extended"];
	[animation setSpeed: 0.25f];
	[contentView addAnimation:(id)animation forKey:@"flip"];
}

//_______________________________________________________________________________

-(SubProcess*) activeProcess
{
	return [processes objectAtIndex: activeTerminal];
}

-(VT100Screen*) activeScreen
{
	return [screens objectAtIndex: activeTerminal];
}

-(VT100Terminal*) activeTerminal
{
	return [terminals objectAtIndex: activeTerminal];
}

-(NSArray *) textviews
{
	return textviews;
}

//_______________________________________________________________________________

-(Menu*) menu { return menu; }
-(UIView*) mainView { return mainView; }
-(UIView*) activeView { return activeView; }
-(GestureView*) gestureView { return gestureView; }
-(PTYTextView*) textView { return [textviews objectAtIndex:activeTerminal]; }
-(UIScroller*) textScroller { return [scrollers objectAtIndex:activeTerminal]; }

@end
