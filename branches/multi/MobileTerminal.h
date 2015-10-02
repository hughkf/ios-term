// MobileTermina.h
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>

@class PTYTextView;
@class ShellKeyboard;
@class SubProcess;
@class VT100Screen;
@class VT100Terminal;
@class GestureView;
@class PieView;
@class StatusView;

#define MAXTERMINALS 4

@interface MobileTerminal : UIApplication
// TODO?
//<KeyboardInputProtocol, InputDelegateProtocol>
{
  UIWindow* window;
  UIView* mainView;
  PTYTextView* textView;
  UIScroller* textScroller;
  ShellKeyboard* keyboardView;
  GestureView* gestureView;
  StatusView* statusView;

  NSMutableArray* processes;
  NSMutableArray* screens;
  NSMutableArray* terminals;
  
  int numTerminals;
  int activeTerminal;

  BOOL controlKeyMode;
  BOOL keyboardShown;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationSuspend:(GSEvent *)event;
- (void)applicationResume:(GSEvent *)event;

- (void)handleStreamOutput:(const char*)c length:(unsigned int)len identifier:(int)tid;
- (void)handleKeyPress:(unichar)c;

// Invoked by GestureMenu
- (void)hideMenu;
- (void)showMenu:(CGPoint)point;
- (void)handleInputFromMenu:(NSString*)input;
- (void)prevTerminal;
- (void)nextTerminal;

// Invoked by SwitcherMenu
- (void)newTerminal;
- (void)closeTerminal;
- (void)toggleKeyboard;

@end
