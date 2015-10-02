// PTYTextView.h
#import <UIKit/UIKit.h>
#import <UIKit/UITiledView.h>

#include <sys/time.h>

@class VT100Screen;

//_______________________________________________________________________________

@interface PTYTextView : UITiledView
{
  // geometry
  float lineHeight;
  float lineWidth;
  float charWidth;
  int numberOfLines;
	
	int termid;

  // data source
  VT100Screen *dataSource;
  UIScroller *textScroller;

	CGPoint scrollOffset;
	
  // cached font details
  CGFontRef fontRef;
  float fontSize;
}

//_______________________________________________________________________________

+ (Class)tileClass;

- (id)initWithFrame:(CGRect)frame source:(VT100Screen*)screen scroller:(UIScroller*)scroller identifier:(int)index;
- (void)dealloc;

- (void)setSource:(VT100Screen*)screen;
- (void)updateAll;

- (void)drawTileFrame:(CGRect)frame tileRect:(CGRect)rect;
- (void)drawRow:(unsigned int)row tileRect:(CGRect)rect;
- (void)refresh;
- (void)refreshCursorRow;
- (void)resetFont;

- (void)updateIfNecessary;
- (void)updateAndScrollToEnd;

- (void)willSlideIn;
- (void)willSlideOut;

- (void)drawBox:(CGContextRef)context
          color:(CGColorRef)color
        boxRect:(CGRect)rect;

- (void)drawChars:(CGContextRef)context
       characters:(unichar*)characters
           count:(int)count
           color:(CGColorRef)color
           point:(CGPoint)point;

@end
