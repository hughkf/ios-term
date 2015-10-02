#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/NSString-UIStringDrawing.h>
#import <UIKit/UIPushButton.h>
#import <UIKit/UIView.h>


@class UIImage;

@interface PieButton : UIPushButton
{
    NSString *dot;
    NSString *command;
    int identifier;
}

@property(nonatomic, copy) NSString *command;
@property(nonatomic, copy) NSString *commandString;

- (id)initWithFrame:(CGRect)frame identifier:(int)identifier;
- (NSString *)dotStringWithCommand:(NSString *)command;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface PieView : UIView
{
    UIImage *pie_back;
    NSMutableArray *buttons;
    PieButton *activeButton;
    id delegate;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, readonly) NSMutableArray *buttons;

- (PieButton *)buttonAtIndex:(int)index;
- (void)selectButton:(PieButton *)button;
- (void)deselectButton:(PieButton *)button;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
