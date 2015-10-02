//
// PTYTile.m
// Terminal

#import "PTYTile.h"
#import "PTYTextView.h"
#import "Log.h"

@implementation PTYTile

- (void)drawRect:(CGRect)rect
{
  //[[PTYTextView sharedInstance] drawTileFrame:[self frame] tileRect:rect];
	[(PTYTextView*)[self superview] drawTileFrame:[self frame] tileRect:rect];
}

@end
