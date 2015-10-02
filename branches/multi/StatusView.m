#import "StatusView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>

@implementation StatusView

- (id)initWithFrame:(CGRect)rect
	delegate:(id)inputDelegate
{
	self = [super initWithFrame:rect];
	delegate = inputDelegate;
	numberTerminals = 0;
	currentTerminal = -1;
	maximumTerminals = NO;

	
	NSBundle *bundle = [NSBundle mainBundle];
	
	NSString* imagePath;
	
	imagePath = [bundle pathForResource: @"status-selected" ofType: @"png"];
	statusSelectedIcon = [[UIImage alloc] initWithContentsOfFile: imagePath];
	
	imagePath = [bundle pathForResource: @"status-unselected" ofType: @"png"];
	statusUnselectedIcon = [[UIImage alloc] initWithContentsOfFile: imagePath];
		
	imagePath = [bundle pathForResource: @"keyboard" ofType: @"png"];
	keyboardIcon = [[UIImage alloc] initWithContentsOfFile: imagePath];

	imagePath = [bundle pathForResource: @"close" ofType: @"png"];
	closeTermIcon = [[UIImage alloc] initWithContentsOfFile: imagePath];

	imagePath = [bundle pathForResource: @"new-enabled" ofType: @"png"];
	newTermEnabledIcon = [[UIImage alloc] initWithContentsOfFile: imagePath];

	imagePath = [bundle pathForResource: @"new-disabled" ofType: @"png"];
	newTermDisabledIcon = [[UIImage alloc] initWithContentsOfFile: imagePath];
	
	imagePath = [bundle pathForResource: @"prefs" ofType: @"png"];
	preferencesIcon = [[UIImage alloc] initWithContentsOfFile: imagePath];
	
	return self;
}

-(void)updateStatusSelected:(int)selected numberTerminals:(int)numTerms atMaximum:(BOOL)atMax
{
	NSLog(@"In status updated");
	numberTerminals = numTerms;
	currentTerminal = selected;
	maximumTerminals = atMax;
	[self setNeedsDisplay];
}


- (void)mouseDown:(GSEvent *)event
{

}

- (void)mouseUp:(GSEvent*)event
{
	CGPoint loc = GSEventGetLocationInWindow(event);
	NSLog(@"Clicked at: X = %f Y = %f", loc.x, loc.y);
	if(loc.x >= 10.0f && loc.x < 40.0f){
		//close terminal
		[delegate closeTerminal];
	} else if (loc.x >= 50.0f && loc.x < 80.0f){
		//new terminal
		[delegate newTerminal];
	} else if (loc.x >= 220.0f && loc.x < 250.0f){
		//prefs
	} else if (loc.x >= 260.0f && loc.x < 310.0f){
		[delegate toggleKeyboard];
	}
}

- (void)gestureStarted:(GSEvent *)event
{

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
	return YES;
}

- (void)drawRect: (CGRect *)rect
{
	NSLog(@"Current Terminal: %d   Number Terminals: %d", currentTerminal, numberTerminals);
	CGContextRef context = UICurrentContext();
	CGRect clearRect = CGRectMake(110.0f, 0.0f, 100.0f, 30.0f);
	CGContextFillRect(context, clearRect);
	
	CGPoint closePoint = CGPointMake(13.0f, 3.0f);
	[closeTermIcon compositeToPoint: closePoint operation: 1];
	
	CGPoint newPoint = CGPointMake(53.0f, 3.0f);
	if(maximumTerminals) {	
		[newTermDisabledIcon compositeToPoint: newPoint operation: 1];
	} else {
		[newTermEnabledIcon compositeToPoint: newPoint operation: 1];
	}
	
	CGPoint prefsPoint = CGPointMake(223.0f, 3.0f);
	[preferencesIcon compositeToPoint: prefsPoint operation: 1];
	
	CGPoint keyboardPoint = CGPointMake(263.0f, 3.0f);
	[keyboardIcon compositeToPoint: keyboardPoint operation: 1];
	
	float statusStart = 160.0f - ((16.0f * numberTerminals) / 2.0f);
	int i;
	for(i = 0; i < numberTerminals; i++){
		CGPoint statusPoint = CGPointMake(statusStart + (16.0f * i), 7.0f);
		if(i == currentTerminal){
			[statusSelectedIcon compositeToPoint: statusPoint operation: 1];
		} else {
			[statusUnselectedIcon compositeToPoint: statusPoint operation: 1];
		}
	}
}

@end
