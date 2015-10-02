#import <UIKit/UIKit.h>
#import <UIKit/UIImage.h>
#import <CoreGraphics/CGGeometry.h>
#import <CoreGraphics/CGColor.h>
#import <CoreGraphics/CGColorSpace.h>
#import <UIKit/NSString-UIStringDrawing.h>

typedef enum {
    kBlue = 1,
    kGray = 2,
    kWhite = 3,
    kPressed = 4
} kButtonStatus;

//_______________________________________________________________________________

@interface PieButton : UIPushButton
{
  NSString * dot;
  NSString * command;
  int identifier;
}

-(id) initWithFrame:(CGRect)frame identifier:(int)identifier;

- (NSString*) command;
- (NSString*) commandString;
- (NSString*) dotStringWithCommand:(NSString *)command;
- (void)      setCommandString:(NSString *)commandString;
- (void)      setCommand:(NSString *)command;

@end

//_______________________________________________________________________________

@interface PieView : UIView 
{
  UIImage * pie_back;
  NSMutableArray * buttons;
  PieButton * activeButton;
  id delegate;
}

-(void) setDelegate:(id)delegate;
-(id) delegate;
- (PieButton*) buttonAtIndex:(int)index; 
- (void) deselectButton:(PieButton*)button;
- (void) selectButton:(PieButton*)button;
- (NSArray*) buttons;
@end
