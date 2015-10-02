#import <UIKit/UIKit.h>

@interface PieView : UIImageView {
    CGRect visibleFrame;
    CGPoint location;
    BOOL _visible;
}

+ (PieView*)sharedInstance;

- (void)showAtPoint:(CGPoint)p;
- (void)hide;
- (void)hideSlow:(BOOL)slow;

@end
