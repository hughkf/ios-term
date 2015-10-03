// TerminalView.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "VT100/VT100TextView.h"
#import "VT100/ColorMap.h"
#import "TerminalKeyboard.h"
#import "CommandLineInterpreter.h"
#import "VT100Terminal.h"

#define KEY_BACKSPACE "\010"

@class VT100TextView;
@class VT100Terminal;
@class SubProcess;
@class PTY;
@class CommandLineInterpreter;

// TerminalView is a wrapper around a subprocess and a VT100 text view, so that
// there can be multiple concurrent terminals/subprocesses running at a time.
// Typically, though, only one terminal is displayed at a time.  It implements
// the terminal keyboard protocol, but only one instance is set as the
// TerminalKeyboards input delegate at any time.
//
// The TerminalView handles restarting a subprocess when it exits.
@interface TerminalView : UIView <TerminalKeyboardProtocol> {
@private
  CommandLineInterpreter *cmd;
  VT100TextView *textView;
  SubProcess *subProcess;
  PTY* pty;
  NSFileHandle* fileHandle;
  NSMutableData* currentCmdline;

  // Keeps track of when the subprocess is stopped, so that we know to start
  // a new one on key press.
  BOOL stopped;
  
  // Determines if this view responds to touch events as copy and paste
  BOOL copyAndPasteEnabled;
}

+ (int) getCurrentCommandLength;
+ (BOOL) editable;
+ (const char*) getPrompt;
- (VT100TextView*) textView;
- (void) processCommandLine: (NSData*)data;
- (NSFileHandle*) fileHandle;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)setFont:(UIFont*)font;
- (ColorMap*)colorMap;
- (int) getWidth;

// Must be invoked to start the sub processes
- (void)startSubProcess;

- (void) writeToScreen:(const char*)msg;

// TerminalKeyboardProtocol
- (void)receiveKeyboardInput:(NSData*)data;

// Configures terminal behavior for responding to touch events
- (void)setCopyPasteEnabled:(BOOL)enabled;

@end
