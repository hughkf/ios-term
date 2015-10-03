//  CommandLineInterpreter.h
//  MobileTerminal
//
//  Created by Hugh Krogh-Freeman on 9/15/15.

#import <Foundation/Foundation.h>
//#import "ls.h"
#import "TerminalView.h"

@class TerminalView;

@interface CommandLineInterpreter : NSObject {
@private
    char* buff;
    TerminalView* view;
}

- (id)init: (TerminalView*) t;
- (void)dealloc;
- (const char*)interpretCommand:(char**)cmd_args : (const char*)cmd : (int) length;
- (char*) string_literal: (const char*) str;
- (char *) ls: (char*) pathname;

@end
