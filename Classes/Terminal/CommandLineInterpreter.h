//  CommandLineInterpreter.h
//  MobileTerminal
//
//  Created by Hugh Krogh-Freeman on 9/15/15.

#import <Foundation/Foundation.h>
#include "common.h"
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

@end
