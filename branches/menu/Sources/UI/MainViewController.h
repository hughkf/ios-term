//
// MainViewController.h
// Terminal

#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIKit.h>

@class GestureView;
@class MobileTerminal;
@class NSMutableArray;
@class PTYTextView;
@class ShellKeyboard;
@class Terminal;
@class UIImageView;
@class UIView;

@interface MainViewController : UIViewController
{
    MobileTerminal *application;

    UIView *mainView;
    ShellKeyboard *keyboardView;
    GestureView *gestureView;

    NSMutableArray *textviews;

    int activeTerminal;

    @private
        int targetOrientation_;
        UIImageView *backBuffer_;
}

@property(nonatomic, readonly) PTYTextView *activeTextView;

- (void)toggleKeyboard;

- (void)addViewForTerminal:(Terminal *)terminal;
- (void)resetViewForTerminal:(int)index;
- (void)removeViewForLastTerminal;
- (void)switchToTerminal:(int)terminal direction:(int)direction;

- (void)updateColors;
- (void)updateFrames:(BOOL)needsRefresh;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
