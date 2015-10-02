//
//  GestureView.m
//  Terminal

#import "GestureView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/CDStructures.h>
#import <GraphicsServices/GraphicsServices.h>
#import "MobileTerminal.h"
#import "Menu.h"
#import "Settings.h"
#import "Tools.h"
#include <math.h>

@implementation GestureView

//_______________________________________________________________________________

- (id) initWithFrame:(CGRect)rect delegate:(id)inputDelegate
{
  self = [super initWithFrame:rect];
  delegate = inputDelegate;
	[super setTapDelegate: self];

	[self setBackgroundColor:colorWithRGBA(0,0,0,0)];
	 
	toggleKeyboardTimer = NULL;
	gestureMode = NO;
  menuTapped = NO;
	
  return self;
}

//_______________________________________________________________________________

-(BOOL) shouldTrack
{
	return ![[MenuView sharedInstance] visible];
}

//_______________________________________________________________________________

- (BOOL) beginTrackingAt:(CGPoint)point withEvent:(id)event
{
	return YES;
}

//_______________________________________________________________________________

- (BOOL) continueTrackingAt:(CGPoint)point previous:(CGPoint)prev withEvent:(id)event
{
  MenuView * menu = [MenuView sharedInstance];
  if (![menu visible])
  {
    [menu stopTimer];
  }
  else
  {
    [menu handleTrackingAt:[menu convertPoint:point fromView:self]];
    return YES;
  }

	return NO;
}

//_______________________________________________________________________________

- (BOOL) endTrackingAt:(CGPoint)point previous:(CGPoint)prev withEvent:(id)event
{
  if (!menuTapped)
  {
    [delegate handleInputFromMenu:[[MenuView sharedInstance] handleTrackingEnd]];
  }
	return YES;
}

//_______________________________________________________________________________

- (void) mouseDown:(GSEvent*)event
{
	mouseDownPos = [delegate viewPointForWindowPoint:GSEventGetLocationInWindow(event)];
  [delegate showMenu:mouseDownPos];
	
	[super mouseDown:event];
}

//_______________________________________________________________________________

-(int) zoneForVector:(CGPoint)vector
{
  float theta = atan2(-vector.y, vector.x);
	return ((7-(lround(theta/M_PI_4)+4)%8)+7)%8;
}

//_______________________________________________________________________________

- (void) mouseUp:(GSEvent*)event
{
	if (gestureMode) 
	{
		gestureMode = NO;
				
		CGPoint vector = CGPointMake(gestureEnd.x - gestureStart.x, gestureEnd.y - gestureStart.y);	
		float r = sqrtf(vector.x*vector.x + vector.y*vector.y);

		if (r < 10) 
		{
			if (gestureFingers == 2)
				[[MobileTerminal application] toggleKeyboard];			
			return;
		}
		else if (r > 30)
		{
			int zone = [self zoneForVector:vector];

			if (gestureFingers >= 2)
			{
        NSString * zoneName = ZONE_KEYS[zone+16];
        NSString * characters = [[[Settings sharedInstance] swipeGestures] objectForKey:zoneName];
        
        if (characters)
        {
          [delegate handleInputFromMenu:characters];
        }
			}
		}
		
		return;
		
	} // end if gestureMode
	
	if (![[MenuView sharedInstance] visible])
	{
		CGPoint end = [delegate viewPointForWindowPoint:GSEventGetLocationInWindow(event)];
		CGPoint vector = CGPointMake(end.x - mouseDownPos.x, end.y - mouseDownPos.y);

		float r = sqrtf(vector.x*vector.x + vector.y*vector.y);
    
		int zone = [self zoneForVector:vector];
		if (r > 30.0f) 
		{
			NSString *characters = nil;

			NSDictionary * swipeGestures = [[Settings sharedInstance] swipeGestures];
      NSString * zoneName = ZONE_KEYS[zone];
      
      if (r < 150.0f)
      {
        characters = [swipeGestures objectForKey:zoneName];
      }
      else
      {
        NSString * longZoneName = ZONE_KEYS[zone+8];
        characters = [swipeGestures objectForKey:longZoneName];
        if (![characters length])
        {
          characters = [swipeGestures objectForKey:zoneName]; 
        }
      }
		      
			if (characters) 
			{
				[self stopToggleKeyboardTimer];
        
        [delegate handleInputFromMenu:characters];
			}
		}
    else if (r < 10.0f)
    {
      mouseDownPos = [delegate viewPointForWindowPoint:GSEventGetLocationInWindow(event)];
      if ([[MenuView sharedInstance] visible])
      {
        [[MenuView sharedInstance] hide];
      }
      else
      {
        [[MenuView sharedInstance] setDelegate:self];
        menuTapped = YES;
        [[MenuView sharedInstance] showAtPoint:mouseDownPos delay:MENU_TAP_DELAY];
      }        
    }
	} // end if menu invisible
  else
  {
    [[MenuView sharedInstance] hide];
  }
	
	[super mouseUp:event];
}

//_______________________________________________________________________________

- (BOOL) canHandleGestures
{
  return YES;
}

//_______________________________________________________________________________

- (BOOL) canHandleSwipes
{
	return YES;
}

//_______________________________________________________________________________

-(CGPoint) gestureCenter:(GSEvent *)event
{
	float cx = 0, cy = 0;
	int i;
	for (i = 0; i < ((GSEventStruct*)event)->numPoints; i++)
	{
		cx += ((GSEventStruct*)event)->points[i].x;
		cy += ((GSEventStruct*)event)->points[i].y;
	}		
	cx /= ((GSEventStruct*)event)->numPoints;
	cy /= ((GSEventStruct*)event)->numPoints;
	return CGPointMake(cx,cy);
}

//_______________________________________________________________________________

- (void) gestureStarted:(GSEvent*)event
{
	[delegate hideMenu];
	gestureMode = YES;
	gestureStart = [delegate viewPointForWindowPoint:[self gestureCenter:event]]; 
}

//_______________________________________________________________________________

- (void) gestureChanged:(GSEvent*)event
{
}

//_______________________________________________________________________________

- (void) gestureEnded:(GSEvent*)event
{
	[delegate hideMenu];
	gestureEnd = [delegate viewPointForWindowPoint:[self gestureCenter:event]];
	gestureFingers = ((GSEventStruct*)event)->numPoints;
}

//_______________________________________________________________________________

-(void) stopToggleKeyboardTimer
{
	if (toggleKeyboardTimer != NULL) 
	{
		[toggleKeyboardTimer invalidate];
		toggleKeyboardTimer = NULL;
	}
}

//_______________________________________________________________________________

- (void) menuButtonPressed:(MenuButton*)button
{
  if (![button isMenuButton])
  {
    BOOL keepMenu = NO;
    NSMutableString * command = [NSMutableString stringWithCapacity:16];
    [command setString:[button command]];
    
    if ([command hasSubstring:[[MobileTerminal menu] dotStringWithCommand:@"keepmenu"]])
    {
      [command removeSubstring:[[MobileTerminal menu] dotStringWithCommand:@"keepmenu"]];
      [[MenuView sharedInstance] deselectButton:button];
      keepMenu = YES;
    }

    if ([command hasSubstring:[[MobileTerminal menu] dotStringWithCommand:@"back"]])
    {
      [command removeSubstring:[[MobileTerminal menu] dotStringWithCommand:@"back"]];
      [[MenuView sharedInstance] popMenu];
      keepMenu = YES;
    }
    
    if (!keepMenu)
    {
      [[MenuView sharedInstance] setDelegate:nil];
      [[MenuView sharedInstance] hide];      
    }        

    [delegate handleInputFromMenu:command];
  }
}

//_______________________________________________________________________________

- (void) menuFadedIn
{
  menuTapped = NO;
}

//_______________________________________________________________________________

- (void) view:(UIView*)view handleTapWithCount:(int)count event:(GSEvent*)event fingerCount:(int)fingers
{
	if (fingers == 1)
	{
    if (count == 2)
    {
      [[MenuView sharedInstance] hide];
      [self stopToggleKeyboardTimer];
      toggleKeyboardTimer = [NSTimer scheduledTimerWithTimeInterval:TOGGLE_KEYBOARD_DELAY 
                                                             target:self 
                                                           selector:@selector(toggleKeyboard) 
                                                           userInfo:NULL repeats:NO];
    }
	}
}

//_______________________________________________________________________________

-(void) toggleKeyboard
{	
	[self stopToggleKeyboardTimer];
	[delegate hideMenu];
	[delegate toggleKeyboard];	
}

//_______________________________________________________________________________

- (BOOL) canBecomeFirstResponder
{
  return NO;
}

//_______________________________________________________________________________

- (BOOL) isOpaque
{
  return NO;
}

//_______________________________________________________________________________

-(void) drawRect:(CGRect)frame
{
	CGRect rect = [self bounds];
	rect.size.height -= 2;
	CGContextRef context = UICurrentContext();
	CGColorRef c = CGColorWithRGBAColor([[Settings sharedInstance] gestureFrameColor]);
	const float pattern[2] = {1,4};
	CGContextSetLineDash(context, 0, pattern, 2);
	CGContextSetStrokeColorWithColor(context, c);
	CGContextStrokeRectWithWidth(context, rect, 1);
	CGContextFlush(context);
}

//_______________________________________________________________________________

@end
