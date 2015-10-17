//  CommandTextView.m
//  MobileTerminal
//
//  Created by Hugh Krogh-Freeman on 9/16/15.

#import <Foundation/Foundation.h>
#import "CommandTextView.h"

@implementation CommandTextView

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    fprintf(stderr, "position: %lu", (unsigned long)range.location);
    if (range.location == 0)
        return YES;
    else
        return NO;
}

@end