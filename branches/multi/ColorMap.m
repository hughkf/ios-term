// ColorMap.m
#import "ColorMap.h"
#import "VT100Terminal.h"


@implementation ColorMap

+ (ColorMap*)sharedInstance
{
  static ColorMap* instance = nil;
  if (instance == nil) {
    instance = [[[ColorMap alloc] init] retain];
  }
  return instance;
}

- (id)init
{
  self = [super init];

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  // System 7.5 colors, why not?
  float darkBlack[] = { 0, 0, 0, 1 };
  table[0] = CGColorCreate(colorSpace, darkBlack);
  float darkRed[] = { 0.67, 0, 0, 1 };
  table[1] = CGColorCreate(colorSpace, darkRed);
  float darkGreen[] = { 0, 0.67, 0, 1 };
  table[2] = CGColorCreate(colorSpace, darkGreen);
  float darkYellow[] = { 0.6, 0.4, 0, 1 };
  table[3] = CGColorCreate(colorSpace, darkYellow);
  float darkBlue[] = { 0, 0, 0.67, 1 };
  table[4] = CGColorCreate(colorSpace, darkBlue);
  float darkMagenta[] = { 0.6, 0, 0.6, 1 };
  table[5] = CGColorCreate(colorSpace, darkMagenta);
  float darkCyan[] = { 0, 0.6, 0.6, 1 };
  table[6] = CGColorCreate(colorSpace, darkCyan);
  float darkWhite[] = { 0.67, 0.67, 0.67, 1 };
  table[7] = CGColorCreate(colorSpace, darkWhite);
  float lightBlack[] = { 0.33, 0.33, 0.33, 1 };
  table[8] = CGColorCreate(colorSpace, lightBlack);
  float lightRed[] = { 1, 0.4, 0.4, 1 };
  table[9] = CGColorCreate(colorSpace, lightRed);
  float lightGreen[] = { 0.4, 1, 0.4, 1 };
  table[10] = CGColorCreate(colorSpace, lightGreen);
  float lightYellow[] = { 1, 1, 0.4, 1 };
  table[11] = CGColorCreate(colorSpace, lightYellow);
  float lightBlue[] = { 0.4, 0.4, 1, 1 };
  table[12] = CGColorCreate(colorSpace, lightBlue);
  float lightMagenta[] = { 1, 0.4, 1, 1 };
  table[13] = CGColorCreate(colorSpace, lightMagenta);
  float lightCyan[] = { 0.4, 1, 1, 1 };
  table[14] = CGColorCreate(colorSpace, lightCyan);
  float lightWhite[] = { 1, 1, 1, 1 };
  table[15] = CGColorCreate(colorSpace, lightWhite);

  // Default colors
  float fgColor[4] = {1, 1, 1, 1};
  defaultFGColor = CGColorCreate(colorSpace, fgColor);
  float bgColor[4] = {0, 0, 0, 1};
  defaultBGColor = CGColorCreate(colorSpace, bgColor);
  float boldColor[4] = {1, 1, 1, 1};
  defaultBoldColor = CGColorCreate(colorSpace, boldColor);
  float cursorColor[4] = {1, 1, 1, 1};
  defaultCursorColor = CGColorCreate(colorSpace, cursorColor);
  float cursorTextColor[4] = {1, 1, 1, 1};
  defaultCursorTextColor = CGColorCreate(colorSpace, cursorTextColor);
  return self;
}

- (void)dealloc
{
  int i;
  for (i = 0; i < 16; i++) {
    CGColorRelease(table[i]);
  }
  CGColorRelease(defaultFGColor);
  CGColorRelease(defaultBGColor);
  CGColorRelease(defaultBoldColor);
  CGColorRelease(defaultCursorColor);
  CGColorRelease(defaultCursorTextColor);
  [super dealloc];
}

- (void)setFGColor:(CGColorRef)color
{
  CGColorRelease(defaultFGColor);
  CGColorRetain(color);
  defaultFGColor = color;
}

- (void)setBGColor:(CGColorRef)color
{
  CGColorRelease(defaultBGColor);
  CGColorRetain(color);
  defaultBGColor = color;
}

- (void)setBoldColor: (CGColorRef)color
{
  CGColorRelease(defaultBoldColor);
  CGColorRetain(color);
  defaultBoldColor = color;
}

- (void)setCursorColor: (CGColorRef)color
{
  CGColorRelease(defaultCursorColor);
  CGColorRetain(color);
  defaultCursorColor = color;
}

- (void)setCursorTextColor: (CGColorRef)color
{
  CGColorRelease(defaultCursorTextColor);
  CGColorRetain(color);
  defaultCursorTextColor = color;
}

- (CGColorRef)defaultFGColor
{
  return defaultFGColor;
}

- (CGColorRef)defaultBGColor
{
  return defaultBGColor;
}

- (CGColorRef)defaultBoldColor
{
  return defaultBoldColor;
}

- (CGColorRef)defaultCursorColor
{
  return defaultCursorColor;
}

- (CGColorRef)defaultCursorTextColor
{
  return defaultCursorTextColor;
}

- (CGColorRef)colorForCode:(unsigned int) index
{
  CGColorRef color;

  if (index & DEFAULT_FG_COLOR_CODE) {  // special colors?
    switch (index) {
      case SELECTED_TEXT:
        [NSException raise:@"Unsupported" format:@"Unsupported color type"];
        break;
      case CURSOR_TEXT:
        color = defaultCursorTextColor;
        break;
      case DEFAULT_BG_COLOR_CODE:
        color = defaultBGColor;
        break;
      default:
        if (index & BOLD_MASK) {
          color = (index-BOLD_MASK == DEFAULT_BG_COLOR_CODE) ?
              defaultBGColor : [self defaultBoldColor];
        } else {
          color = defaultFGColor;
        }
    }
  } else {
    index &= 0xff;

    if (index < 16) {
      color = table[index];
    } else if (index < 232) {
      index -= 16;
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      float components[] = {
        (index/36) ? ((index / 36) * 40 + 55) / 256.0 : 0 ,
        (index%36)/6 ? (((index % 36) / 6) * 40 + 55 ) / 256.0:0 ,
        (index%6) ? ((index % 6) * 40 + 55) / 256.0:0,
        1.0
      };
      color = CGColorCreate(colorSpace, components);
    } else {
      index -= 232;
      //color=[CGColorRef colorWithCalibratedWhite:(index*10+8)/256.0 alpha:1];
      [NSException raise:@"Unsupported" format:@"Unsupported color type"];
    }
  }
  return color;
}

@end
