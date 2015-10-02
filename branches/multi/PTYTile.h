// PTYTile.h
//
// PTYTextView creates PTYTiles, which call back to PTYTextView when they
// are asked to be drawn.

#import <UIKit/UIKit.h>
#import <UIKit/UITile.h>

@interface PTYTile : UITile
{
}

- (void)drawRect:(CGRect)rect;

@end
