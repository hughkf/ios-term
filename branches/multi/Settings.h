// Settings.h

#import <Foundation/Foundation.h>

// TODO: Listeners for when settings change
@interface Settings : NSObject
{
  int width;
  int height;
  NSString* font;
}

+ (Settings*)sharedInstance;

- (id)init;

- (int)width;
- (int)height;
- (NSString*)font;
- (void)setWidth:(int)width;
- (void)setHeight:(int)height;
- (void)setFont:(NSString*)terminalFont;

@end
