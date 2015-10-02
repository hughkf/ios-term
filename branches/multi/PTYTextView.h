// PTYTextView.h
#import <UIKit/UIKit.h>
#import <UIKit/UITiledView.h>

#include <sys/time.h>

@class VT100Screen;

@interface PTYTextView : UITiledView
{
  BOOL CURSOR;

  // geometry
  float lineHeight;
  float lineWidth;
  float charWidth;
  int numberOfLines;

  int margin;
  int vmargin;

  // data source
  VT100Screen *dataSource;
  UIScroller *textScroller;

  // cached font details
  CGFontRef fontRef;
  float fontSize;
}

+ (PTYTextView*)sharedInstance;
+ (Class)tileClass;

- (id)initWithFrame:(CGRect)rect
             source:(VT100Screen*)screen
           scroller:(UIScroller*)scroller;
- (void)dealloc;

- (void)setSource:(VT100Screen*)screen;

- (void)drawTileFrame:(CGRect)frame tileRect:(CGRect)rect;
- (void)drawRow:(unsigned int)row tileRect:(CGRect)rect;
- (void)refresh;

// Only draws tiles which are dirty
- (void)updateIfNecessary;
- (void)updateAndScrollToEnd;

- (void)updateAll;

- (void)drawBox:(CGContextRef)context
          color:(CGColorRef)color
        boxRect:(CGRect)rect;

- (void)drawChar:(CGContextRef)context
       character:(char)c
           color:(CGColorRef)color
           point:(CGPoint)point;

@end
