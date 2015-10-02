//
//  GestureView.h
//  Terminal

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//_______________________________________________________________________________

struct GSPathPoint {
	char unk0;
	char unk1;
	short int status;
	int unk2;
	float x;
	float y;
};

//_______________________________________________________________________________

typedef struct {
	int unk0;
	int unk1;
	int type;
	int subtype;
	float unk2;
	float unk3;
	float x;
	float y;
	int timestamp1;
	int timestamp2;
	int unk4;
	int modifierFlags;
	int unk5;
	int unk6;
	int mouseEvent;
	short int dx;
	short int fingerCount;
	int unk7;
	int unk8;
	char unk9;
	char numPoints;
	short int unk10;
	struct GSPathPoint points[10];
} GSEventStruct;

//_______________________________________________________________________________

@protocol GestureInputProtocol
- (void) showMenu:(CGPoint)point;
- (void) hideMenu;
- (void) handleInputFromMenu:(NSString*)input;
- (void) toggleKeyboard;
@end

//_______________________________________________________________________________

@interface GestureView : UIControl 
{
	CGPoint mouseDownPos;
	CGPoint gestureStart;
	CGPoint gestureEnd;
	int			gestureFingers;

  id			delegate;
	BOOL		gestureMode;
  BOOL    menuTapped;
	
	NSTimer * toggleKeyboardTimer;
}

- (id) initWithFrame:(CGRect)rect delegate:(id)inputDelegate;
-(void) stopToggleKeyboardTimer;

@end
