#import "Settings.h"

@implementation Settings

+ (Settings*)sharedInstance
{
  static Settings* instance = nil;
  if (instance == nil) {
    instance = [[Settings alloc] init];
  }
  return instance;
}

- (id)init
{
  self = [super init];
  width = 45;
  height = 15; // Was originally height = 17; - reduced to 15 to account for the status bar
  font = @"CourierNewBold";
  return self;
}

- (int)width
{
  return width;
}

- (int)height
{
  return height;
}

- (NSString*)font
{
  return font;
}

- (void)setWidth:(int)w
{
  width = w;
}

- (void)setHeight:(int)h
{
  height = h;
}

- (void)setFont:(NSString*)terminalFont;
{
  [font release];
  font = terminalFont;
  [font retain];
}

@end
