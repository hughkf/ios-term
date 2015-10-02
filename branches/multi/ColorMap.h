// ColorMap.h
//
// ColorMap is not at all thread safe.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface ColorMap : NSObject
{
  CGColorRef table[16];
  CGColorRef defaultFGColor;
  CGColorRef defaultBGColor;
  CGColorRef defaultBoldColor;
  CGColorRef defaultCursorColor;
  CGColorRef defaultCursorTextColor;
}

+ (ColorMap*)sharedInstance;

- (CGColorRef)defaultFGColor;
- (CGColorRef)defaultBGColor;
- (CGColorRef)defaultBoldColor;
- (CGColorRef)colorForCode:(unsigned int)index;
- (CGColorRef)defaultCursorColor;
- (CGColorRef)defaultCursorTextColor;
- (void)setFGColor:(CGColorRef)color;
- (void)setBGColor:(CGColorRef)color;
- (void)setBoldColor:(CGColorRef)color;
- (void)setCursorColor:(CGColorRef)color;
- (void)setCursorTextColor:(CGColorRef)color;

@end
