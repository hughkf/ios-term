// ShellKeyboard.m
#import "ShellKeyboard.h"

// Override settings of the default keyboard implementation
@implementation UIKeyboardImpl (DisableFeatures)

- (BOOL)autoCapitalizationPreference
{
  return false;
}

- (BOOL)autoCorrectionPreference
{
  return false;
}

@end

@interface TextInputHandler : UITextView
{
  ShellKeyboard* shellKeyboard;
}

- (id)initWithKeyboard:(ShellKeyboard*)keyboard;

@end

@implementation TextInputHandler

- (id)initWithKeyboard:(ShellKeyboard*)keyboard;
{
  self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
  shellKeyboard = keyboard;
  return self;
}

- (BOOL)webView:(id)fp8 shouldDeleteDOMRange:(id)fp12
{
  [shellKeyboard handleKeyPress:0x08];
}

- (BOOL)webView:(id)fp8 shouldInsertText:(id)character
                       replacingDOMRange:(id)fp16
                             givenAction:(int)fp20
{
  if ([character length] != 1) {
    [NSException raise:@"Unsupported" format:@"Unhandled multi-char insert!"];
    return false;
  }
  [shellKeyboard handleKeyPress:[character characterAtIndex:0]];
}

@end

// ShellKeyboard

@implementation ShellKeyboard

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  inputDelegate = nil;
  inputView = [[TextInputHandler alloc] initWithKeyboard:self];
  return self;
}

- (UITextView*)inputView
{
  return inputView;
}

- (void)setInputDelegate:(id)delegate;
{
  inputDelegate = delegate;
}

- (void)handleKeyPress:(unichar)c
{
  [inputDelegate handleKeyPress:c];
}

@end
