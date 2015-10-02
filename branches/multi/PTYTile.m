// PTYTile.m
#import "PTYTile.h"
#import "PTYTextView.h"

@implementation PTYTile

- (void)drawRect:(CGRect)rect
{
  [[PTYTextView sharedInstance] drawTileFrame:[self frame] tileRect:rect];
}

@end
