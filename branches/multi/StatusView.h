#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SubProcess;

@protocol StatusInputProtocol
- (void)newTerminal;
- (void)closeTerminal;
- (void)toggleKeyboard;
@end

@interface StatusView : UIView {
	id delegate;
	int numberTerminals;
	int currentTerminal;
	BOOL maximumTerminals;
	
	UIImage* statusSelectedIcon;
	UIImage* statusUnselectedIcon;
	UIImage* keyboardIcon;
	UIImage* closeTermIcon;
	UIImage* newTermEnabledIcon;
	UIImage* newTermDisabledIcon;
	UIImage* preferencesIcon;
}

- (id)initWithFrame:(CGRect)rect
	delegate:(id)inputDelegate;
- (void)updateStatusSelected:(int)selected 
		numberTerminals:(int)numTerms
		atMaximum:(BOOL)atMax;

@end
