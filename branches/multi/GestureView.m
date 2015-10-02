#import "GestureView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>

@implementation GestureView

- (id)initWithFrame:(CGRect)rect
           delegate:(id)inputDelegate
{
	self = [super initWithFrame:rect];
	delegate = inputDelegate;
	return self;
}

CGPoint start;
BOOL gesture;

- (void)mouseDown:(GSEvent *)event
{
	gesture = NO;
	start = GSEventGetLocationInWindow(event);
	NSLog(@"GV MouseDown: %f, %f", start.x, start.y);
	[delegate showMenu:start];
}

- (void)mouseUp:(GSEvent*)event
{
	if (gesture) {
		return;
	}
	
	CGPoint end = GSEventGetLocationInWindow(event);
	CGPoint vector = CGPointMake(end.x - start.x, end.y - start.y);
	
	float absx = (vector.x > 0) ? vector.x : -vector.x;
	float absy = (vector.y > 0) ? vector.y : -vector.y;
	float r = (absx > absy) ? absx : absy;
	float theta = atan2(-vector.y, vector.x);
	int zone = (int)((theta / (2 * 3.1415f * 0.125f)) + 0.5f + 4.0f);
	if (r > 30.0f) {
		NSString *characters = nil;
		switch (zone) {
			case 0:
			case 8:  // Left
				characters = @"\x1B[D";
				break;
			case 2:  // Down
				characters = @"\x1B[B";
				break;
			case 4:  // Right
				characters = @"\x1B[C";
				break;
			case 6:  // Up
				characters = @"\x1B[A";
				break;
			case 5:  // ^C
				characters = @"\x03";
				break;
			case 7:  // ^[
				characters = @"\x1B";
				break;
			case 1: // Tab
				characters = @"\x09";
				break;
			case 3:  // ^D
				characters = @"\x04";
				break;
    }
		if (characters) {
			[delegate handleInputFromMenu:characters];
		}
  }
	[delegate hideMenu];
}

- (void)gestureStarted:(GSEvent *)event
{
	gesture = YES;
	[delegate hideMenu];
	
	struct CGPoint pt;
   struct CGPoint pt2;
	
	pt = GSEventGetInnerMostPathPosition(event);
	pt2 = GSEventGetOuterMostPathPosition(event);
	
	float avgx = (pt.x + pt2.x) / 2.0;
	float avgy = (pt.y + pt2.y) / 2.0;
	
	start = CGPointMake(avgx, avgy);
}

- (void)gestureEnded:(GSEvent *)event
{
	struct CGPoint pt;
   struct CGPoint pt2;
	
	pt = GSEventGetInnerMostPathPosition(event);
	pt2 = GSEventGetOuterMostPathPosition(event);
	
	float avgx = (pt.x + pt2.x) / 2.0;
	float avgy = (pt.y + pt2.y) / 2.0;
	
	CGPoint end = CGPointMake(avgx, avgy);
	CGPoint vector = CGPointMake(end.x - start.x, end.y - start.y);
	
	float absx = (vector.x > 0) ? vector.x : -vector.x;
	float absy = (vector.y > 0) ? vector.y : -vector.y;
	
	float r = (absx > absy) ? absx : absy;
	float theta = atan2(-vector.y, vector.x);
	int zone = (int)((theta / (2 * 3.1415f * 0.125f)) + 0.5f + 4.0f);
	if (r > 30.0f) {
		switch (zone) {
			case 0:
			case 8:  // Left
				[delegate prevTerminal];
				break;
			case 2:  // Down
				//NSLog(@"Swiped down");
				break;
			case 4:  // Right
				[delegate nextTerminal];
				break;
			case 6:  // Up
				//NSLog(@"Swiped up");
				break;
			case 5:  // ^C
				//NSLog(@"Swiped up-Right");
				break;
			case 7:  // ^[
				//NSLog(@"Swiped up-Left");
				break;
			case 1: // Tab
				//NSLog(@"Swiped down-left");
				break;
			case 3:  // ^D
				//NSLog(@"Swiped down-right");
				break;
      }
   }
}

- (BOOL)canBecomeFirstResponder
{
	return NO;
}

- (BOOL)canHandleGestures
{
	return YES;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect: (CGRect *)rect
{
}

@end
