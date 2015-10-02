//  CommandLineInterpreter.h
//  MobileTerminal
//
//  Created by Hugh Krogh-Freeman on 9/15/15.

#import <Foundation/Foundation.h>
//#import "common.h"
#import "TerminalView.h"

@class TerminalView;

@interface CommandLineInterpreter : NSObject {
@private
    char* buff;
    TerminalView* view;
}

- (id)init: (TerminalView*) t;
- (void)dealloc;
- (char*)interpretCommand:(char**)cmd_args : (const char*)cmd : (int) length;

@end
