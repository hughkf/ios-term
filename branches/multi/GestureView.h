#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SubProcess, PieView;

@protocol GestureInputProtocol
- (void)showMenu:(CGPoint)point;
- (void)hideMenu;
- (void)handleInputFromMenu:(NSString*)input;
- (void)toggleKeyboard;
- (void)nextTerminal;
- (void)prevTerminal;
@end

@interface GestureView : UIView {
  id delegate;
}

- (id)initWithFrame:(CGRect)rect
           delegate:(id)inputDelegate;

@end
