// TerminalView.m
// MobileTerminal

#import "TerminalView.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#import "Settings.h"
#import "VT100/VT100TextView.h"
#import "SubProcess/SubProcess.h"
#import "CommandLineInterpreter.h"
#import "VT100/VT100Terminal.h"
#import "MenuEditViewController.h"
#import "MenuSettings.h"

@class MenuEditViewController;
@class MenuSettings;

@implementation TerminalView

static const char* kProcessExitedMessage =
"[Process completed]\r\n"
"Press any key to restart.\r\n";

static const char* prompt = " $ ";
static int currentCommandLength;

- (void) writeToScreen:(const char*)msg {
    NSData* message = [NSData dataWithBytes:msg length:strlen(msg)];
    [textView readInputStream:message];
}

- (VT100TextView*) textView {
    return textView;
}

- (void)startSubProcess
{
    stopped = NO;
    subProcess = [[SubProcess alloc] init];
    [subProcess start];
    
    // The PTY will be sized correctly on the first call to layoutSubViews
    pty = [[PTY alloc] initWithFileHandle:[subProcess fileHandle]];
    
    // Schedule an async read of the subprocess.  Invokes our callback when
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(dataAvailable:)
                                            name:NSFileHandleReadCompletionNotification
                                            object:[subProcess fileHandle]];
    [[subProcess fileHandle] readInBackgroundAndNotify];
}

- (void)releaseSubProcess
{
    if (subProcess == nil) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    stopped = YES;
    [pty release];
    [subProcess stop];
    [subProcess release];
}

- (void)dataAvailable:(NSNotification *)aNotification {
    //fprintf(stdout, "dataAvailable: begin\n");

    NSData* data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    //currentCmdline = data;
    
    // I would expect from the documentation that an EOF would be present as
    // an entry in the userinfo dictionary as @"NSFileHandleError", but that is
    // never present.  Instead, it seems to just appear as an empty data
    // message.  This usually happens when someone just types "exit".  Simply
    // restart the subprocess when this happens.
    
    // On EOF, either (a) the user typed "exit" or (b) the terminal never
    // started in first place due to a misconfiguration of the BSD subsystem
    // (can't find /bin/login, etc).  To allow the user to proceed in case (a),
    // display a message with instructions on how to restart the shell.  We
    // don't restart automatically in case of (b), which would put us in an
    // infinite loop.  Print a message on the screen with instructions on how
    // to restart the process.
    if ([data length] == 0)
    {
        NSData* message = [NSData dataWithBytes:kProcessExitedMessage
                                     length:strlen(kProcessExitedMessage)];
        [textView readInputStream:message];
        [self releaseSubProcess];
        return;
    }
    // Forward the subprocess data into the terminal character handler
    [textView readInputStream:data];
  
    // Queue another read
    [[subProcess fileHandle] readInBackgroundAndNotify];

    return;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    //fprintf(stdout, "initWithCoder: begin\n");
    self = [super initWithCoder:decoder];
    if (self != nil) {
        editable = NO;
        subProcess = nil;
        currentCmdline = [[NSMutableData alloc] init];
        fileHandle = nil;
        copyAndPasteEnabled = NO;
    	textView = [[VT100TextView alloc] initWithCoder:decoder];
        [textView setFrame:self.frame];
        [self addSubview:textView];
        cmd = [[CommandLineInterpreter alloc ] init : self];
    }
    return self;
}

- (NSFileHandle*) fileHandle {
    return fileHandle;
}

- (void)dealloc {
  [currentCmdline release];
  [self releaseSubProcess];
  [super dealloc];
}

/* TODO: fix this */
- (int) getWidth {
//    return [pty getWidth];
    return 1024;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  //fprintf(stdout, "layoutSubviews: begin\n");
  // Make sure that the text view is laid out, which re-computes the terminal
  // size in rows and columns.
  [textView layoutSubviews];

  // Send the terminal the actual size of our vt100 view.  This should be
  // called any time we change the size of the view.  This should be a no-op if
  // the size has not changed since the last time we called it.
  [pty setWidth:[textView width] withHeight:[textView height]];
}

- (void)receiveKeyboardInput:(NSData*)data
{
    if (0 < [TerminalKeyboard backspaceCount]){
        currentCommandLength -= [TerminalKeyboard backspaceCount];
        [TerminalKeyboard setBackspaceCount: 0];
    } else {
        currentCommandLength = currentCommandLength +  [data length];
    }
    editable = ([textView cursorX] >= 3);
    
    if (stopped) {
        // The sub process previously exited, restart it at the users request.
        [textView clearScreen];
        [self startSubProcess];
    } else {
        // Forward the data from the keyboard directly to the subprocess
        [[subProcess fileHandle] writeData:data];
        [self processCommandLine : data];
    }
}

+ (int) getCurrentCommandLength {
    return currentCommandLength;
}

- (void) processCommandLine: (NSData*)data {
    NSString *cmdString;

    if (currentCmdline == nil)
        currentCmdline = [[NSMutableData alloc] init];
    [currentCmdline appendData:data];
    NSData *immutableData = [NSData dataWithData:currentCmdline];
    
    cmdString = [[NSString alloc] initWithData:immutableData encoding:NSUTF8StringEncoding];
    unichar last = [cmdString characterAtIndex:[cmdString length] - 1];
    
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:last] &&  [immutableData length] == 1)
    {
        currentCmdline = nil;
        [self prompt];
    } else if ([[NSCharacterSet newlineCharacterSet] characterIsMember:last] && [immutableData length] > 1)
    {
        currentCmdline = nil;
        currentCommandLength = 0;
        
        //get char* & strip newline
        char* tmp = strdup([cmdString UTF8String]);
        tmp[ strlen(tmp) - 1 ] = '\0'; //strip trailing newline
        
        //trim whitespace
        while(isspace(*tmp)) tmp++;;
        
        //process command
        size_t pieces = 0;
        char* orig = strdup(tmp); 
        char** args = strsplit(tmp, " ", &pieces);
        const char* retString = [cmd interpretCommand: args : orig : pieces];
        if (retString != NULL){
            [self writeToScreen: retString];
        }
        [self prompt];
    }
    [cmdString release];
}

char **strsplit(char* s, const char* delim, size_t* numtokens) {
    // these three variables are part of a very common idiom to
    // implement a dynamically-growing array
    size_t tokens_alloc = 1;
    size_t tokens_used = 0;
    char **tokens = (char**)calloc(tokens_alloc, sizeof(char*));
    
    char *token, *strtok_ctx;
    for (token = strtok_r(s, delim, &strtok_ctx);
         token != NULL;
         token = strtok_r(NULL, delim, &strtok_ctx)) {
        // check if we need to allocate more space for tokens
        if (tokens_used == tokens_alloc) {
            tokens_alloc *= 2;
            tokens = (char**)realloc(tokens, tokens_alloc * sizeof(char*));
        }
        tokens[tokens_used++] = strdup(token);
    }
    
    // cleanup
    if (tokens_used == 0) {
        free(tokens);
        tokens = NULL;
    } else {
        tokens = (char**)realloc(tokens, tokens_used * sizeof(char*));
    }
    *numtokens = tokens_used;
    //free(s);
    
    return tokens;
}

//char *trim_leading_whitespace(char *str)
//{
//    char *end;
//    
//    // Trim leading space
//    while(isspace(*str)) str++;
//    
//    if(*str == 0)  // All spaces?
//        return str;
//    
//    // Trim trailing space
//    end = str + strlen(str) - 1;
//    while(end > str && isspace(*end)) end--;
//    
//    // Write new null terminator
//    *(end+1) = 0;
//    
//    return str;
//}

//char** str_split(char* a_str, const char a_delim)
//{
//        char** result    = 0;
//        size_t count     = 0;
//        char* tmp        = a_str;
//        char* last_comma = 0;
//        char delim[2];
//        delim[0] = a_delim;
//        delim[1] = 0;
//        
//        /* Count how many elements will be extracted. */
//        while (*tmp)
//        {
//            if (a_delim == *tmp)
//            {
//                count++;
//                last_comma = tmp;
//            }
//            tmp++;
//        }
//        
//        /* Add space for trailing token. */
//        count += last_comma < (a_str + strlen(a_str) - 1);
//        
//        /* Add space for terminating null string so caller
//         knows where the list of returned strings ends. */
//        count++;
//        
//        result = malloc(sizeof(char*) * count);
//    
//        if (result)
//        {
//            size_t idx  = 0;
//            char* token = strtok(a_str, delim);
//            
//            while (token)
//            {
//                assert(idx < count);
//                *(result + idx++) = strdup(token);
//                token = strtok(0, delim);
//            }
//            assert(idx == count - 1);
//            *(result + idx) = 0;
//        }
//        return result;
//}

- (void)fillDataWithSelection:(NSMutableData*)data;
{
  return [textView fillDataWithSelection:data];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [super touchesBegan:touches withEvent:event];
  
  //fprintf(stdout, "touchesBegan: begin\n");
  if (!copyAndPasteEnabled) {
    return;
  }  
  if ([textView hasSelection]) {
    [textView clearSelection];
  } else {
    UITouch *theTouch = [touches anyObject];
    CGPoint point = [theTouch locationInView:self];
    [textView setSelectionStart:point];
    [textView setSelectionEnd:point];
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  [super touchesMoved:touches withEvent:event];

  //fprintf(stdout, "touchesMoved: begin\n");
  if (!copyAndPasteEnabled) {
    return;
  }  
  if ([textView hasSelection]) {
    UITouch *theTouch = [touches anyObject];
    CGPoint point = [theTouch locationInView:self];
    [textView setSelectionEnd:point];
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];

  //fprintf(stdout, "touchesEnded: begin\n");
  if (!copyAndPasteEnabled) {
    return;
  }
  CGRect rect = [textView cursorRegion];
  if ([textView hasSelection]) {
    UITouch *theTouch = [touches anyObject];
    [textView setSelectionEnd:[theTouch locationInView:self]];
    rect = [textView selectionRegion];
    if (fabs(rect.size.width) < 1 && fabs(rect.size.height) < 1) {
      rect = [textView cursorRegion];
    }
  }
  
  // bring up editing menu.
  UIMenuController *theMenu = [UIMenuController sharedMenuController];
  [theMenu setTargetRect:rect inView:self];
  [theMenu setMenuVisible:YES animated:YES];
}

- (void)setCopyPasteEnabled:(BOOL)enabled;
{
  //fprintf(stdout, "setCopyPasteEnabled: begin\n");
  copyAndPasteEnabled = enabled;
  // Reset any previous UI state for copy and paste
  UIMenuController *theMenu = [UIMenuController sharedMenuController];
  [theMenu setMenuVisible:NO];
  [textView clearSelection];
}

+ (const char*) getPrompt {
    return prompt;
}

- (void)prompt {
    editable = ([textView cursorX] >= 3);
    [[subProcess fileHandle] writeData: [NSData dataWithBytes:prompt length:strlen(prompt)]];
}

//prevent deleting the prompt
static BOOL editable;

+ (BOOL) editable {
    return editable;
}
                
- (void)setFont:(UIFont*)font
{
  //fprintf(stdout, "setFont: begin\n");
  [self prompt];
  [textView setFont:font];
}

- (ColorMap*)colorMap
{
  //fprintf(stdout, "colorMap: begin\n");
  return [textView colorMap];
}

@end
