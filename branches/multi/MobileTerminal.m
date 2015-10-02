// MobileTerminal.h
#define DEBUG_METHOD_TRACE    1

#import "MobileTerminal.h"
#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import "ShellKeyboard.h"
#import "PTYTextView.h"
#import "SubProcess.h"
#import "VT100Terminal.h"
#import "VT100Screen.h"
#import "GestureView.h"
#import "PieView.h"
#import "StatusView.h"

@implementation MobileTerminal

- (void) applicationDidFinishLaunching:(NSNotification*)unused
{
  controlKeyMode = NO;

  CGRect frame = [UIHardware fullScreenApplicationContentRect];
  frame.origin.y = 0;

  keyboardShown = YES;
  
  numTerminals = 0;
  activeTerminal = 0;

  processes = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
  screens = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
  terminals = [[NSMutableArray arrayWithCapacity: MAXTERMINALS] retain];
  
  VT100Terminal* terminal = [[VT100Terminal alloc] init];
  VT100Screen* screen = [[VT100Screen alloc] init];
  [screen setTerminal:terminal];
  [terminal setScreen:screen];

  [screens addObject: screen];
  [terminals addObject: terminal];
  
  window = [[UIWindow alloc] initWithContentRect:frame];

  CGRect textFrame = CGRectMake(0.0f, 0.0f, 320.0f, 215.0f);
  textScroller = [[UIScroller alloc] initWithFrame:textFrame];
  textView = [[PTYTextView alloc] initWithFrame:textFrame
                                         source:screen
                                       scroller:textScroller];
												
  CGRect statusFrame = CGRectMake(0.0f, 215.0f, 320.0f, 30.0f);
  statusView = [[StatusView alloc] initWithFrame:statusFrame delegate:self];


  CGRect keyFrame = CGRectMake(0.0f, 245.0f, 320.0f, 480.0f); 
  keyboardView = [[ShellKeyboard alloc] initWithFrame:keyFrame];
  [keyboardView setInputDelegate:self];

  mainView = [[UIView alloc] initWithFrame: frame];
  [mainView addSubview:[keyboardView inputView]];

  [window orderFront: self];
  [window makeKey: self];
  [window setContentView: mainView];
  [window _setHidden:NO];

  SubProcess* process = [[SubProcess alloc] initWithDelegate:self identifier: 0];
  
  [processes addObject: process];

	numTerminals += 1;

	[statusView updateStatusSelected: activeTerminal numberTerminals: numTerminals atMaximum: NO];
  
  CGRect gestureFrame = CGRectMake(0.0f, 0.0f, 240.0f, 215.0f);
  gestureView =
    [[GestureView alloc] initWithFrame:gestureFrame delegate:self];

  [mainView addSubview:textScroller];
  [mainView addSubview:keyboardView];
  [mainView addSubview:[keyboardView inputView]];
  [mainView addSubview:gestureView];
  [mainView addSubview:statusView];
  [mainView addSubview:[PieView sharedInstance]];


  // Shows momentarily and hides so the user knows its there
  [[PieView sharedInstance] hideSlow:YES];

  // Input focus
  [[keyboardView inputView] becomeFirstResponder];
}

// Suspend/Resume: We have to hide then show again the keyboard view to get it
// to properly acheive focus on suspend and resume.

- (void)applicationSuspend:(GSEvent *)event
{
	BOOL shouldQuit;
	int i;
	shouldQuit = YES;

	for(i = 0; i < [processes count]; i++){
		if( [ [processes objectAtIndex: i] isRunning] ){
			shouldQuit = NO;
			break;
		}
	}
	
  if (shouldQuit) {
    exit(0);
  }

  [[keyboardView inputView] removeFromSuperview];
  [keyboardView removeFromSuperview];
}

- (void)applicationResume:(GSEvent *)event
{
  [mainView addSubview:keyboardView];
  [mainView addSubview:[keyboardView inputView]];
  [[keyboardView inputView] becomeFirstResponder];
}

- (void)applicationExited:(GSEvent *)event
{
	int i;
	for(i = 0; i < [processes count]; i++){
		[[processes objectAtIndex: i] close];
	}
}

// Process output from the shell and pass it to the screen
- (void)handleStreamOutput:(const char*)c length:(unsigned int)len identifier:(int)tid
{
#if DEBUG_METHOD_TRACE
  NSLog(@"%s: 0x%x (%d bytes, %d termid)", __PRETTY_FUNCTION__, self, len, tid);
  NSLog(@"[processes retainCount] = %d", [processes retainCount]);
#endif

  if(tid < 0 || tid >= [terminals count]){
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
  
  if(tid == activeTerminal){
		[textView performSelectorOnMainThread:@selector(updateAndScrollToEnd)
                             withObject:nil
                          waitUntilDone:NO];
	}
}

// Process input from the keyboard
- (void)handleKeyPress:(unichar)c
{
#if DEBUG_METHOD_TRACE
  NSLog(@"%s: 0x%x (c=0x%02x)", __PRETTY_FUNCTION__, self, c);
#endif

  if (!controlKeyMode) {
    if (c == 0x2022) {
      controlKeyMode = YES;
      return;
    }
  } else {
    // was in ctrl key mode, got another key
    if (c < 0x60 && c > 0x40) {
      // Uppercase
      c -= 0x40;
    } else if (c < 0x7B && c > 0x61) {
      // Lowercase
      c -= 0x60;
    }
    controlKeyMode = NO;
  }
  // Not sure if this actually matches anything.  Maybe support high bits later?
  if ((c & 0xff00) != 0) {
    NSLog(@"Unsupported unichar: %x", c);
    return;
  }
  char simple_char = (char)c;
  
  SubProcess* process = [processes objectAtIndex: activeTerminal];
  [process write:&simple_char length:1];
}

- (void)hideMenu
{
  [[PieView sharedInstance] hide];
}

- (void)showMenu:(CGPoint)point
{
  [[PieView sharedInstance] showAtPoint:point];
};

- (void)handleInputFromMenu:(NSString*)input
{
  SubProcess* process = [processes objectAtIndex: activeTerminal];
  [process write:[input cString] length:[input length]];
}

- (void)toggleKeyboard
{
  // TODO: Bring back keyboard hide/show animation
  CGRect textFrame;
  CGRect gestureFrame;
	CGRect statusFrame;
  int height;
  int width;
  if (keyboardShown) {
    gestureFrame = CGRectMake(0.0f, 0.0f, 240.0f, 430.0f);
    textFrame = CGRectMake(0.0f, 0.0f, 320.0f, 430.0);
		statusFrame = CGRectMake(0.0f, 430.0f, 320.0f, 30.0f);
    keyboardShown = NO;
    width = 45;
    height = 30; //reduced to account for status bar
    [keyboardView removeFromSuperview];
  } else {
    gestureFrame = CGRectMake(0.0f, 0.0f, 240.0f, 215.0f);
    textFrame = CGRectMake(0.0f, 0.0, 320.0f, 215.0f);
		statusFrame = CGRectMake(0.0f, 215.0f, 320.0f, 30.0f);
    keyboardShown = YES;
    width = 45;
    height = 15; // reduced to account for status bar
    [mainView addSubview:keyboardView];
  }
  [textScroller setFrame:textFrame];
  [textView setFrame:textFrame];
  [gestureView setFrame:gestureFrame];
	[statusView setFrame:statusFrame];
	int i;
	for(i = 0; i < [processes count]; i++){
		[[processes objectAtIndex: i] setWidth:width height:height];
	}
	for(i = 0; i < [screens count]; i++){
		[[screens objectAtIndex: i] resizeWidth:width height:height];
	}
}

-(void) newTerminal
{
	if(numTerminals >= MAXTERMINALS){
		NSLog(@"Can't create new terminal, already at maximum number");
		return;
	}
  VT100Terminal* terminal = [[VT100Terminal alloc] init];
  VT100Screen* screen = [[VT100Screen alloc] init];
  [screen setTerminal:terminal];
  [terminal setScreen:screen];

  [screens addObject: screen];
  [terminals addObject: terminal];

  SubProcess* process = [[SubProcess alloc] initWithDelegate:self identifier: numTerminals];
  
  [processes addObject: process];
  
  [textView setSource: screen];
  
	activeTerminal = numTerminals;
  numTerminals += 1;

	[statusView updateStatusSelected: activeTerminal 
		numberTerminals: numTerminals 
		atMaximum: (numTerminals == MAXTERMINALS)
	];
}

-(void) closeTerminal
{
	VT100Screen* screen = [screens objectAtIndex: activeTerminal];
	VT100Terminal* terminal = [terminals objectAtIndex: activeTerminal];
	SubProcess* process = [processes objectAtIndex: activeTerminal];
	int i;

	[process closeSession];
	
	[screens removeObjectAtIndex: activeTerminal];
	[terminals removeObjectAtIndex: activeTerminal];
	[processes removeObjectAtIndex: activeTerminal];
	
		
	NSLog(@"Got Active Items");
	
	numTerminals -= 1;
	
	if(numTerminals == 0){
		[self newTerminal];
	} else {
		for(i = activeTerminal; i < [processes count]; i++){
			SubProcess* sp = [processes objectAtIndex: i];
			[sp setIdentifier: i];
		}
	
		if (activeTerminal >= numTerminals)
			activeTerminal = numTerminals - 1;
		
		VT100Screen* newscreen = [screens objectAtIndex: activeTerminal];
		[textView setSource: newscreen];
	}	
	
	//[process dealloc];
	[screen release];
	[terminal release];
	
	[statusView updateStatusSelected: activeTerminal 
		numberTerminals: numTerminals 
		atMaximum: (numTerminals == MAXTERMINALS)
	];
}

-(void) prevTerminal
{
	if(activeTerminal > 0){
		activeTerminal -= 1;
		VT100Screen* screen = [screens objectAtIndex: activeTerminal];
		[textView setSource: screen];
		[statusView updateStatusSelected: activeTerminal 
			numberTerminals: numTerminals 
			atMaximum: (numTerminals == MAXTERMINALS)
		];
	} else {
		NSLog(@"Can't Switch - at last terminal");
	}
}

-(void) nextTerminal
{
	if(activeTerminal < numTerminals - 1){
		activeTerminal += 1;
		VT100Screen* screen = [screens objectAtIndex: activeTerminal];
		[textView setSource: screen];
		[statusView updateStatusSelected: activeTerminal 
			numberTerminals: numTerminals 
			atMaximum: (numTerminals == MAXTERMINALS)
		];
		
	} else {
		NSLog(@"Can't Switch - at last terminal");
	}
}

@end
