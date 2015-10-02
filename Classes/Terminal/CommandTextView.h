//
//  CommandTextView.h
//  MobileTerminal
//
//  Created by Hugh Krogh-Freeman on 9/16/15.
//
//

@interface CommandTextView : UITextView <UITextViewDelegate> {

}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
@end
