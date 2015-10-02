//
//  Preferences.m
//  Terminal

#import "Preferences.h"
#import "MobileTerminal.h"
#import "Settings.h"
#import "PTYTextView.h"
#import "Constants.h"
#import "Color.h"
#import "Menu.h"
#import "PieView.h"
#import "Log.h"

#import <UIKit/UISimpleTableCell.h> 
#import "UIFieldEditor.h"

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation UIPickerTable (PickerTableExtensions)

//_______________________________________________________________________________

-(void) _selectRow:(int)row byExtendingSelection:(BOOL)extend withFade:(BOOL)fade scrollingToVisible:(BOOL)scroll withSelectionNotifications:(BOOL)notify 
{
	if (row >= 0)
	{
		[[[self selectedTableCell] iconImageView] setFrame:CGRectMake(0,0,0,0)];
		[super _selectRow:row byExtendingSelection:extend withFade:fade scrollingToVisible:scroll withSelectionNotifications:notify];		
		[[[self selectedTableCell] iconImageView] setFrame:CGRectMake(0,0,0,0)];
	}
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation UIPickerView (PickerViewExtensions)

-(float) tableRowHeight { return 22.0f; }
-(id) delegate { return _delegate; }

//_______________________________________________________________________________

-(void) _sendSelectionChanged
{
	int c, r;
	
	for (c = 0; c < [self numberOfColumns]; c++)
	{
		UIPickerTable * table = [self tableForColumn:c];
		for (r = 0; r < [table numberOfRows]; r++)
		{
			[[[table cellAtRow:r column:0] iconImageView] setFrame:CGRectMake(0,0,0,0)]; 
		}
	}
	
	if ([self delegate])
	{
		if ([[self delegate] respondsToSelector:@selector(fontSelectionDidChange)])
		{
			[[self delegate] performSelector:@selector(fontSelectionDidChange)];
		}
	}
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation FontChooser

//_______________________________________________________________________________

- (id) initWithFrame: (struct CGRect)rect
{
	self = [super initWithFrame:rect];
	[self createFontList];
	
	fontPicker = [[UIPickerView alloc] initWithFrame: [self bounds]];
	[fontPicker setDelegate: self];
	
	pickerTable = [fontPicker createTableWithFrame: [self bounds]];
	[pickerTable setAllowsMultipleSelection: FALSE];
	
	UITableColumn * fontColumn = [[UITableColumn alloc] initWithTitle: @"Font" identifier:@"font" width: rect.size.width];
	
	[fontPicker columnForTable: fontColumn];
	
	[self addSubview:fontPicker];

	return self;
}

//_______________________________________________________________________________

- (void) setDelegate:(id) aDelegate
{
	delegate = aDelegate;
}

//_______________________________________________________________________________

-(id) delegate
{
	return delegate;
}

//_______________________________________________________________________________

- (void) createFontList
{
	NSFileManager * fm = [NSFileManager defaultManager];

	// hack to make compiler happy
	// what could have been easy like:
	//		fontNames = [[fm directoryContentsAtPath:@"/var/Fonts" matchingExtension:@"ttf" options:0 keepExtension:NO] retain];
	// now becomes:
	SEL sel = @selector(directoryContentsAtPath:matchingExtension:options:keepExtension:);
	NSMethodSignature * sig = [[fm class] instanceMethodSignatureForSelector:sel];
	NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
	NSString * path = @"/System/Library/Fonts/Cache";
	NSString * ext = @"ttf";
	int options = 0;
	BOOL keep = NO;
	[invocation setArgument:&path atIndex:2];
	[invocation setArgument:&ext atIndex:3];
	[invocation setArgument:&options atIndex:4];
	[invocation setArgument:&keep atIndex:5];
	[invocation setTarget:fm];
	[invocation setSelector:sel];
	[invocation invoke];
	[invocation getReturnValue:&fontNames];
	[fontNames retain];
	// hack ends here
}

//_______________________________________________________________________________

- (int) numberOfColumnsInPickerView:(UIPickerView*)picker
{
	return 1;
}

//_______________________________________________________________________________

- (int) pickerView:(UIPickerView*)picker numberOfRowsInColumn:(int)col
{
	return [fontNames count];
}

//_______________________________________________________________________________
- (UIPickerTableCell*) pickerView:(UIPickerView*)picker tableCellForRow:(int)row inColumn:(int)col
{
	UIPickerTableCell * cell = [[UIPickerTableCell alloc] init];
	
	if (col == 0)
	{
		[cell setTitle:[fontNames objectAtIndex:row]];
	}
	
	[[cell titleTextLabel] setFont:[UISimpleTableCell defaultFont]];
	[cell setSelectionStyle:0];
	[cell setShowSelection:YES];
	[[cell iconImageView] setFrame:CGRectMake(0,0,0,0)]; 
	
	return cell;
}

//_______________________________________________________________________________

-(float)pickerView:(UIPickerView*)picker tableWidthForColumn: (int)col
{
	return [self bounds].size.width-40.0f;
}

//_______________________________________________________________________________

- (int) rowForFont: (NSString*)fontName
{
	int i;
	for (i = 0; i < [fontNames count]; i++)
	{
		if ([[fontNames objectAtIndex:i] isEqualToString:fontName])
		{
			return i;
		}
	}	
	return 0;
}

//_______________________________________________________________________________

- (void) selectFont: (NSString*)fontName
{
	selectedFont = fontName;
	int row = [self rowForFont:fontName];
	[fontPicker selectRow:row inColumn:0 animated:NO];
	[[fontPicker tableForColumn:0] _selectRow:row byExtendingSelection:NO withFade:NO scrollingToVisible:YES withSelectionNotifications:YES];		
}

//_______________________________________________________________________________

- (NSString*) selectedFont
{
	int row = [fontPicker selectedRowForColumn:0];
	return [fontNames objectAtIndex:row];
}

//_______________________________________________________________________________

-(void) fontSelectionDidChange
{
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(setFont:)])
			[[self delegate] performSelector:@selector(setFont:) withObject:[self selectedFont]];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation FontView

//_______________________________________________________________________________

-(id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];

	PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
	PreferencesGroup * group = [PreferencesGroup groupWithTitle:@"" icon:nil];
	[prefGroups addGroup:group];
	group.titleHeight = 220;

	CGRect chooserRect = CGRectMake(0, 0, frame.size.width, 210);
	fontChooser = [[FontChooser alloc] initWithFrame:chooserRect];
	[self addSubview:fontChooser];
	
	UIPreferencesControlTableCell * cell;
	group = [PreferencesGroup groupWithTitle:@"" icon:nil];
	cell = [group addIntValueSlider:@"Size" range:NSMakeRange(7, 13) target:self action:@selector(sizeSelected:)];
	sizeSlider = [cell control];
	cell = [group addFloatValueSlider:@"Width" minValue:0.5f maxValue:1.0f target:self action:@selector(widthSelected:)];
	widthSlider = [cell control];
	[prefGroups addGroup:group];

	[self setDataSource:prefGroups];
	[self reloadData];
	
	return self;
}

//_______________________________________________________________________________

- (void) selectFont:(NSString*)font size:(int)size width:(float)width
{
	[fontChooser selectFont:font];	
	[sizeSlider setValue:(float)size];
	[widthSlider setValue:width];
}

//_______________________________________________________________________________

- (void) sizeSelected:(UISliderControl*)control
{
	[control setValue:floor([control value])]; 
	[[PreferencesController sharedInstance] setFontSize:(int)[control value]];
}

//_______________________________________________________________________________

- (void) widthSelected:(UISliderControl*)control
{
	[[PreferencesController sharedInstance] setFontWidth:[control value]];
}

//_______________________________________________________________________________

-(FontChooser*) fontChooser { return fontChooser; }; 

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation ColorButton

-(id) initWithFrame:(CGRect)frame colorRef:(RGBAColorRef)c
{
	self = [super initWithFrame:frame];
	
  [self setBackgroundColor:colorWithRGBA(1,1,1,0)];
  
	colorRef = c;
	
	return self;
}

//_______________________________________________________________________________

-(RGBAColor) color 
{
	return * colorRef;
}

//_______________________________________________________________________________

-(void) setColorRef:(RGBAColorRef)cref
{
  colorRef = cref;
  [self setNeedsDisplay];  
}

//_______________________________________________________________________________

-(void) drawRect:(struct CGRect)rect
{
  CGContextRef context = UICurrentContext();
	CGContextSetFillColorWithColor(context, CGColorWithRGBAColor([self color]));
  CGContextSetStrokeColorWithColor(context, colorWithRGBA(0.5,0.5,0.5,1));
  
  UIBezierPath * path = [UIBezierPath roundedRectBezierPath:CGRectMake(2, 2, rect.size.width-4, rect.size.height-4)
                                         withRoundedCorners:0xffffffff
                                           withCornerRadius:7.0f];	 
  
  [path fill];
  [path stroke];

  CGContextFlush(context);  
}

//_______________________________________________________________________________

- (void) colorChanged:(NSArray*)colorValues
{
	*colorRef = RGBAColorMakeWithArray(colorValues);
  [self setNeedsDisplay];
}

//_______________________________________________________________________________

- (void) view: (UIView*) view handleTapWithCount:(int)count event:(id)event 
{
	PreferencesController * prefs = [PreferencesController sharedInstance];
	[[prefs colorView] setColor:[self color]];
	[[prefs colorView] setDelegate:self];
	[prefs pushViewControllerWithView:[prefs colorView] navigationTitle:[[self superview] title]];
}	

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation ColorView

-(id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
  PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
  PreferencesGroup * group;

  group = [PreferencesGroup groupWithTitle:@"Color" icon:nil];
	colorField = [group addColorField];
	[prefGroups addGroup:group];
  
	group = [PreferencesGroup groupWithTitle:@"Values" icon:nil];
	redSlider   = [[group addFloatValueSlider:@"Red"   minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
	greenSlider = [[group addFloatValueSlider:@"Green" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
	blueSlider  = [[group addFloatValueSlider:@"Blue"  minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
	[prefGroups addGroup:group];

  group = [PreferencesGroup groupWithTitle:@"" icon:nil];
	alphaSlider = [[group addFloatValueSlider:@"Alpha" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
	[prefGroups addGroup:group];

  [self setDataSource:prefGroups];
	[self reloadData];

	return self;
}

//_______________________________________________________________________________

-(RGBAColor) color 
{
  return color;
}

//_______________________________________________________________________________

-(void) setColor:(RGBAColor)color_
{
  color = color_;
  [colorField setColor:color];
  [redSlider   setValue:color.r];
  [greenSlider setValue:color.g];  
  [blueSlider  setValue:color.b];  
  [alphaSlider setValue:color.a];
}

//_______________________________________________________________________________

-(void) setDelegate:(id)delegate_
{
  delegate = delegate_;
}

//_______________________________________________________________________________

-(id) delegate
{
  return delegate;
}

//_______________________________________________________________________________

-(void) sliderChanged:(id)slider
{
  color = RGBAColorMake([redSlider value], [greenSlider value], [blueSlider value], [alphaSlider value]);

  [colorField setColor:color];

	if ([self delegate] && [[self delegate] respondsToSelector:@selector(colorChanged:)])
	{
		NSArray * colorArray = RGBAColorToArray(color);
		[[self delegate] performSelector:@selector(colorChanged:) withObject:colorArray];
	}
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation TerminalPreferences

//_______________________________________________________________________________

-(id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
	PreferencesGroup * group;

  group = [PreferencesGroup groupWithTitle:@"" icon:nil];
	fontButton = [group addPageButton:@"Font"];
	[prefGroups addGroup:group];
	
	sizeGroup = [PreferencesGroup groupWithTitle:@"Size" icon:nil];
	autosizeSwitch = [[sizeGroup addSwitch:@"Auto Adjust" target:self action:@selector(autosizeSwitched:)] control];
	widthCell = [sizeGroup addIntValueSlider:@"Width" range:NSMakeRange(40, 60) target:self action:@selector(widthSelected:)];
  widthSlider = [widthCell control];
	[prefGroups addGroup:sizeGroup];	

  group = [PreferencesGroup groupWithTitle:@"Arguments" icon:nil];
  argumentField = [[group addTextField:@"" value:@""] textField];
  [argumentField setEditingDelegate:self];  
	[prefGroups addGroup:group];	
  
	group = [PreferencesGroup groupWithTitle:@"Colors" icon:nil];
  color0 = [group addColorPageButton:@"Background"         colorRef:nil];
  color1 = [group addColorPageButton:@"Normal Text"        colorRef:nil];
  color2 = [group addColorPageButton:@"Bold Text"          colorRef:nil];
  color3 = [group addColorPageButton:@"Cursor Text"        colorRef:nil];
  color4 = [group addColorPageButton:@"Cursor Background"  colorRef:nil];
	[prefGroups addGroup:group];	

	[self setDataSource:prefGroups];
	[self reloadData];

	return self;
}

//_______________________________________________________________________________

-(BOOL) keyboardInput:(id)fieldEditor shouldInsertText:(NSString*)text isMarkedText:(BOOL)marked
{
  if ([text isEqualToString:@"\n"])
  {
    [config setArgs:[argumentField text]];
    if ([self keyboard]) [self setKeyboardVisible:NO animated:YES];
  }
  return YES;
}

//_______________________________________________________________________________

-(void) fontChanged
{
	[fontButton setValue:[config fontDescription]];
}

//_______________________________________________________________________________

-(void) setTerminalIndex:(int)index
{
	terminalIndex = index;
	config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];
	[self fontChanged];
  [argumentField setText:[config args]];
	[autosizeSwitch setValue:([config autosize] ? 1.0f : 0.0f)];
	[widthSlider setValue:[config width]];
	if ([config autosize])
	{
		[sizeGroup removeCell:widthCell];
	}
	else if (![config autosize])
	{
		[sizeGroup addCell:widthCell];
	}
  
  [color0 setColorRef:&config.colors[0]];
  [color1 setColorRef:&config.colors[1]];
  [color2 setColorRef:&config.colors[2]];
  [color3 setColorRef:&config.colors[3]];
  [color4 setColorRef:&config.colors[4]];
  
	[self reloadData];		
}

//_______________________________________________________________________________

- (void) autosizeSwitched:(UISliderControl*)control
{
	BOOL autosize = ([control value] == 1.0f);
	[config setAutosize:autosize];
	if (autosize)
	{
		[sizeGroup removeCell:widthCell];
	}
	else
	{
		[sizeGroup addCell:widthCell];
	}
	[self reloadData];		
}

//_______________________________________________________________________________

- (void) widthSelected:(UISliderControl*)control
{
	[control setValue:floor([control value])];
	[config setWidth:(int)[control value]];
	[config setWidth:(int)[control value]];
}

//_______________________________________________________________________________

- (void) prepareToPop
{
  if ([self keyboard])
  {    
    [self setKeyboardVisible:NO animated:NO];
  }
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation GestureTableCell

-(id) initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
	[self setShowSelection:NO];
  pieView = [[PieView alloc] initWithFrame:frame];
  [pieView setOrigin:CGPointMake(57,10)];
	[self addSubview:pieView];
  
  return self;
}

//_______________________________________________________________________________

- (void)drawBackgroundInRect:(struct CGRect)fp8 withFade:(float)fp24
{
    [super drawBackgroundInRect: fp8 withFade: fp24];
    CGContextRef context = UICurrentContext();
    CGContextSaveGState(context);
    CGContextAddPath(context, [_fillPath _pathRef]);
    CGContextClip(context);
    CGContextSetFillColorWithColor(context, colorWithRGBA(0,0,0,1));
    CGContextFillRect(context, fp8);
    CGContextRestoreGState(context);
}

//_______________________________________________________________________________

- (float) getHeight
{
  return [self frame].size.height;
}

//_______________________________________________________________________________

- (PieView*) pieView { return pieView; }

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation GesturePreferences

-(id) initWithFrame:(CGRect)frame swipes:(int)swipes_
{
	self = [super initWithFrame:frame];
	
  swipes = swipes_;
  
	PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
	menuGroup = [PreferencesGroup groupWithTitle:@"" icon:nil];
  
	GestureTableCell * cell = [[GestureTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 235.0f)];
  pieView = [cell pieView];
  
  int i;
  for (i = 0; i < 8; i++)
  {
    NSString * command = [[[Settings sharedInstance] swipeGestures] objectForKey:ZONE_KEYS[(i+8-2)%8 + swipes * 8]];
    if (command != nil) [[pieView buttonAtIndex:i] setCommand:command];
  }
  
  [pieView setDelegate:self];
	[menuGroup addCell:cell];

  commandField = [[menuGroup addTextField:@"Command" value:@""] textField];
  [commandField setEditingDelegate:self];
  
  [prefGroups addGroup:menuGroup];

  if (swipes == 0) 
  {
    PreferencesGroup * group = [PreferencesGroup groupWithTitle:@"" icon:nil];
    [group addPageButton:@"Long Swipes"];
    [group addPageButton:@"Two Finger Swipes"];
    [prefGroups addGroup:group];

    group = [PreferencesGroup groupWithTitle:@"" icon:nil];
    [group addColorPageButton:@"Gesture Frame Color" colorRef:[[Settings sharedInstance] gestureFrameColorRef]];
    [prefGroups addGroup:group];
  }
  
	[self setDataSource:prefGroups];
	[self reloadData];
	
  editButton = nil;
  
  [pieView selectButton:[pieView buttonAtIndex:2]];
  [self pieButtonPressed:[pieView buttonAtIndex:2]];
  
	return self;
}

//_______________________________________________________________________________

- (void) pieButtonPressed:(PieButton*)button
{
  editButton = button;
  [self update];  
}

//_______________________________________________________________________________

- (void) update
{
  [commandField setText:[editButton commandString]];
  
  [self reloadData];
}

//_______________________________________________________________________________
/*
-(BOOL) respondsToSelector:(SEL)sel
{
  return [super respondsToSelector:sel];
}
*/

//_______________________________________________________________________________
-(void) keyboardInputChanged:(UIFieldEditor*)fieldEditor
{
  [editButton setTitle:[commandField text]];
}

//_______________________________________________________________________________

-(BOOL) keyboardInput:(id)fieldEditor shouldInsertText:(NSString*)text isMarkedText:(BOOL)marked
{  
  if ([fieldEditor proxiedView] == commandField && [text isEqualToString:@"\n"])
  {
    if ([self keyboard]) [self setKeyboardVisible:NO animated:YES];
    [editButton setCommandString:[NSString stringWithString:[commandField text]]];
    if ([editButton title] == nil || [[editButton title] length] == 0)
    {
      [editButton setTitle:[commandField text]];
    }
    
    [self update];
  }
  return YES;
}

//_______________________________________________________________________________

- (void) prepareToPop
{
  if ([self keyboard])
  {    
    [self setKeyboardVisible:NO animated:NO];
  }

  int i;
  for (i = 0; i < 8; i++)
  {
    NSString * command = [[pieView buttonAtIndex:i] command]; 
    NSString * zone = ZONE_KEYS[(i+8-2)%8 + swipes * 8];
    [[Settings sharedInstance] setCommand:command forGesture:zone];
  }
}

//_______________________________________________________________________________
- (PieView*) pieView { return pieView; }

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation MenuTableCell

-(id) initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];

	[self setShowSelection:NO];
  menu = [[MenuView alloc] init];
  [menu setShowsEmptyButtons:YES];
  [menu loadMenu];
  [menu setOrigin:CGPointMake(70,30)];
	[self addSubview:menu];
  
  return self;
}

//_______________________________________________________________________________

- (void)drawBackgroundInRect:(struct CGRect)fp8 withFade:(float)fp24
{
  [super drawBackgroundInRect: fp8 withFade: fp24];
  CGContextRef context = UICurrentContext();
  CGContextSaveGState(context);
  CGContextAddPath(context, [_fillPath _pathRef]);
  CGContextClip(context);
  CGContextSetFillColorWithColor(context, colorWithRGBA(0,0,0,1));
  CGContextFillRect(context, fp8);
  CGContextRestoreGState(context);
}

//_______________________________________________________________________________

- (float) getHeight
{
  return [self frame].size.height;
}

//_______________________________________________________________________________

- (MenuView*) menu { return menu; }

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation MenuPreferences

-(id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
	menuGroup = [PreferencesGroup groupWithTitle:@"" icon:nil];

	MenuTableCell * cell = [[MenuTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 235.0f)];
  menuView = [cell menu];
  [menuView setDelegate:self];
	[menuGroup addCell:cell];
  titleField = [[menuGroup addTextField:@"Title" value:@""] textField];
  [titleField setEditingDelegate:self];  
  commandField = [[menuGroup addTextField:@"Command" value:@""] textField];
  [commandField setEditingDelegate:self];  

  submenuControl = [menuGroup addSwitch:@"Submenu" target:self action:@selector(submenuSwitched:)];
  submenuSwitch = [submenuControl control];

  [submenuControl setShowDisclosure:NO];
  [submenuControl setUsesBlueDisclosureCircle:YES];
  [submenuControl setDisclosureClickable:YES];	
  
	[prefGroups addGroup:menuGroup];
		
	[self setDataSource:prefGroups];
	[self reloadData];
	
  editButton = nil;
  
  [menuView selectButton:[menuView buttonAtIndex:0]];
  [self menuButtonPressed:[menuView buttonAtIndex:0]];
  
	return self;
}

//_______________________________________________________________________________
- (void) submenuSwitched:(UISliderControl*)control
{
  if ([control value] == 1)
  {
    [Menu menuWithItem:[editButton item]];
  }
  else
  {
    [[editButton item] setSubmenu:nil];
  }
  [editButton update];
  [self update];
}

//_______________________________________________________________________________

-(BOOL) shouldLoadMenuWithButton:(MenuButton*)button
{
  return NO;
}

//_______________________________________________________________________________

- (void) openSubmenuAction
{
  int index = [[editButton item] index];
  PreferencesController * prefControl = [PreferencesController sharedInstance];
  MenuPreferences * newMenuPrefs = [[MenuPreferences alloc] initWithFrame:[[prefControl view] bounds]];
  [[newMenuPrefs menuView] loadMenu:[[editButton item] submenu]];
  [newMenuPrefs selectButtonAtIndex:index];
  [prefControl pushViewControllerWithView:newMenuPrefs navigationTitle:[editButton title]];
}

//_______________________________________________________________________________

- (void) menuButtonPressed:(MenuButton*)button
{
  editButton = button;
  [self update];  
}

//_______________________________________________________________________________

- (void) selectButtonAtIndex:(int)index
{
  editButton = [[self menuView] buttonAtIndex:index];
  [menuView selectButton:editButton];
  [self update];
}

//_______________________________________________________________________________

- (void) update
{
  [titleField setText:[editButton title]];
  [commandField setText:[editButton commandString]];
  [submenuSwitch setValue:[editButton isMenuButton] ? 1 : 0];
  [submenuControl setShowDisclosure:[editButton isNavigationButton] animated:YES];
  
  [UIView beginAnimations:@"slideSwitch"];
  
  if ([editButton isNavigationButton])
  {
    [[submenuControl _disclosureView] addTarget:self action:@selector(openSubmenuAction) forEvents:64];
    [submenuSwitch setOrigin:CGPointMake(156.0f, 9.0f)];
  }
  else
  {
    [submenuSwitch setOrigin:CGPointMake(206.0f, 9.0f)];
  }
  
  [UIView endAnimations];
  [self reloadData];
}

//_______________________________________________________________________________

-(BOOL) respondsToSelector:(SEL)sel
{
  return [super respondsToSelector:sel];
}

//_______________________________________________________________________________
-(void) keyboardInputChanged:(UIFieldEditor*)fieldEditor
{
  if ([fieldEditor proxiedView] == titleField)
    [editButton setTitle:[titleField text]];
}

//_______________________________________________________________________________

-(BOOL) keyboardInput:(id)fieldEditor shouldInsertText:(NSString*)text isMarkedText:(BOOL)marked
{  
  if ([fieldEditor proxiedView] == commandField && [text isEqualToString:@"\n"])
  {
    if ([self keyboard]) [self setKeyboardVisible:NO animated:YES];
    [editButton setCommandString:[NSString stringWithString:[commandField text]]];
    if ([editButton title] == nil || [[editButton title] length] == 0)
    {
      [editButton setTitle:[commandField text]];
      [titleField setText:[commandField text]];
    }
    
    [self update];
  }
  return YES;
}

//_______________________________________________________________________________

- (void) prepareToPop
{
  if ([self keyboard])
  {    
    [self setKeyboardVisible:NO animated:NO];
  }
}

//_______________________________________________________________________________
- (MenuView*) menuView { return menuView; }

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PreferencesController

//_______________________________________________________________________________

+ (PreferencesController*) sharedInstance
{
  static PreferencesController * instance = nil;
  if (instance == nil)  instance = [[PreferencesController alloc] init];
  return instance;
}

//_______________________________________________________________________________

-(id) init
{
	self = [super init];
	application = [MobileTerminal application];
	return self;
}

//_______________________________________________________________________________

-(void) initViewStack
{	
	[self pushViewControllerWithView:[self settingsView] navigationTitle:@"Settings"];
	[[self navigationBar] setBarStyle:1];
	[[self navigationBar] showLeftButton:@"Done" withStyle: 5 rightButton:nil withStyle: 0];	
}

//_______________________________________________________________________________
-(void) multipleTerminalsSwitched:(UISwitchControl*)control
{
	BOOL multi = ([control value] == 1.0f);
	[[Settings sharedInstance] setMultipleTerminals:multi];
		
	if (!multi)
	{
		[terminalGroup removeCell:terminalButton2];
		[terminalGroup removeCell:terminalButton3];
		[terminalGroup removeCell:terminalButton4];
		[settingsView reloadData];
	}
	else
	{
		[terminalGroup addCell:terminalButton2];
		[terminalGroup addCell:terminalButton3];
		[terminalGroup addCell:terminalButton4];
		[settingsView reloadData];
	}	
}

//_______________________________________________________________________________

-(UIPreferencesTable*) settingsView
{
	if (!settingsView)
	{
		PreferencesGroups * prefGroups = [[PreferencesGroups alloc] init];
		PreferencesGroup * group;
    
    // ------------------------------------------------------------- menu & gestures
    
    group = [PreferencesGroup groupWithTitle:@"Menu & Gestures" icon:nil];
    [group addPageButton:@"Menu"];
		[group addPageButton:@"Gestures"];
		[prefGroups addGroup:group];		
    		
    // ------------------------------------------------------------- terminals

		terminalGroup = [PreferencesGroup groupWithTitle:@"Terminals" icon:nil];
    
		BOOL multi = [[Settings sharedInstance] multipleTerminals];

    if (MULTIPLE_TERMINALS)
    {
      [terminalGroup addSwitch:@"Multiple Terminals" 
                            on:multi
                        target:self 
                        action:@selector(multipleTerminalsSwitched:)];
    }
				
		terminalButton1 = [terminalGroup addPageButton:@"Terminal 1"];

    if (MULTIPLE_TERMINALS)
    {
      terminalButton2 = [terminalGroup addPageButton:@"Terminal 2"];
      terminalButton3 = [terminalGroup addPageButton:@"Terminal 3"];
      terminalButton4 = [terminalGroup addPageButton:@"Terminal 4"];

      if (!multi)
      {
        [terminalGroup removeCell:terminalButton2];
        [terminalGroup removeCell:terminalButton3];
        [terminalGroup removeCell:terminalButton4];
      }
    }
		
		[prefGroups addGroup:terminalGroup];
		    
    // ------------------------------------------------------------- about
    
		group = [PreferencesGroup groupWithTitle:@"" icon:nil];
		[group addPageButton:@"About"];
		[prefGroups addGroup:group];

		UIPreferencesTable * table = [[UIPreferencesTable alloc] initWithFrame: [[self view] bounds]];
		[table setDataSource:prefGroups];
		[table reloadData];
		[table enableRowDeletion:YES animated:YES];
		settingsView = table;
	}
	return settingsView;	
}

//_______________________________________________________________________________

- (void) view: (UIView*) view handleTapWithCount: (int) count event: (id) event 
{
	NSString * title = [(UIPreferencesTextTableCell*)view title];
	  
	if ([title isEqualToString:@"About"])
	{
		[self pushViewControllerWithView:[self aboutView] navigationTitle:@"About"];
	}
	else if ([title isEqualToString:@"code.google.com/p/mobileterminal"])
	{
		[[MobileTerminal application] openURL:[NSURL URLWithString:@"http://code.google.com/p/mobileterminal/"]];	
	}
	else if ([title isEqualToString:@"Font"])
	{
		[self pushViewControllerWithView:[self fontView] navigationTitle:title];
	}
	else if ([title isEqualToString:@"Menu"])
	{
		[self pushViewControllerWithView:[self menuView] navigationTitle:title];
	}  
	else if ([title isEqualToString:@"Gestures"])
	{
		[self pushViewControllerWithView:[self gestureView] navigationTitle:title];
	}  
	else if ([title isEqualToString:@"Long Swipes"])
	{
		[self pushViewControllerWithView:[self longSwipeView] navigationTitle:title];
	}  
	else if ([title isEqualToString:@"Two Finger Swipes"])
	{
		[self pushViewControllerWithView:[self twoFingerSwipeView] navigationTitle:title];
	}  
	else
	{
		terminalIndex = [[title substringFromIndex:9] intValue] - 1;
		[[self terminalView] setTerminalIndex:terminalIndex];
		[self pushViewControllerWithView:[self terminalView] navigationTitle:title];
	}
}

//_______________________________________________________________________________

- (void) navigationBar: (id)bar buttonClicked: (int)button 
{
	switch (button)
	{
		case 1:
			[application togglePreferences];
			break;
	}
}

//_______________________________________________________________________________

-(id) aboutView
{
	if (!aboutView)
	{
		PreferencesGroups * aboutGroups = [[[PreferencesGroups alloc] init] retain];
		PreferencesGroup * group;

		group = [PreferencesGroup groupWithTitle:@"MobileTerminal" icon:nil];
		[group addValueField:@"Version" value:[NSString stringWithFormat:@"1.0 (%@)", SVN_VERSION]];
		[aboutGroups addGroup:group];

		group = [PreferencesGroup groupWithTitle:@"Homepage" icon:nil];
		[group addPageButton:@"code.google.com/p/mobileterminal"];
		[aboutGroups addGroup:group];

		group = [PreferencesGroup groupWithTitle:@"Contributors" icon:nil];
		[group addValueField:@"" value:@"allen.porter"];
		[group addValueField:@"" value:@"craigcbrunner"];
		[group addValueField:@"" value:@"vaumnou"]; 
		[group addValueField:@"" value:@"andrebragareis"];
		[group addValueField:@"" value:@"aaron.krill"];
		[group addValueField:@"" value:@"kai.cherry"];
		[group addValueField:@"" value:@"elliot.kroo"];
		[group addValueField:@"" value:@"validus"];
		[group addValueField:@"" value:@"DylanRoss"];
		[group addValueField:@"" value:@"lednerk"];
		[group addValueField:@"" value:@"tsangk"];
		[group addValueField:@"" value:@"joseph.jameson"];
		[group addValueField:@"" value:@"gabe.schine"];
		[group addValueField:@"" value:@"syngrease"];
		[group addValueField:@"" value:@"maball"];
		[group addValueField:@"" value:@"lennart"];
		[group addValueField:@"" value:@"monsterkodi"];	
		[aboutGroups addGroup:group];

		CGRect viewFrame = [[super view] bounds];
		UIPreferencesTable * table = [[UIPreferencesTable alloc] initWithFrame:viewFrame];
		[table setDataSource:aboutGroups];
		[table reloadData];

		aboutView = table;
	}
	return aboutView;
}

//_______________________________________________________________________________

-(FontView*) fontView
{
	if (!fontView)
	{
		fontView = [[FontView alloc] initWithFrame:[[super view] bounds]];
		[[fontView fontChooser] setDelegate:self]; 
	}
	
	return fontView;
}

//_______________________________________________________________________________

-(MenuPreferences*) menuView
{
	if (!menuView) menuView = [[MenuPreferences alloc] initWithFrame:[[super view] bounds]];
	return menuView;
}

//_______________________________________________________________________________

-(GesturePreferences*) gestureView
{
	if (!gestureView) gestureView = [[GesturePreferences alloc] initWithFrame:[[super view] bounds] swipes:0];
	return gestureView;
}

//_______________________________________________________________________________

-(GesturePreferences*) longSwipeView
{
	if (!longSwipeView) longSwipeView = [[GesturePreferences alloc] initWithFrame:[[super view] bounds] swipes:1];
	return longSwipeView;
}

//_______________________________________________________________________________

-(GesturePreferences*) twoFingerSwipeView
{
	if (!twoFingerSwipeView) twoFingerSwipeView = [[GesturePreferences alloc] initWithFrame:[[super view] bounds] swipes:2];
	return twoFingerSwipeView;
}

//_______________________________________________________________________________

-(ColorView*) colorView
{
	if (!colorView) colorView = [[ColorView alloc] initWithFrame:[[super view] bounds]];
	return colorView;
}

//_______________________________________________________________________________

-(TerminalPreferences*) terminalView
{
	if (!terminalView) terminalView = [[TerminalPreferences alloc] initWithFrame:[[super view] bounds]];
	return terminalView;
}

//_______________________________________________________________________________

-(void)setFontSize:(int)size
{
	TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];

	[config setFontSize:size];
}

//_______________________________________________________________________________

-(void)setFontWidth:(float)width
{
	TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];
	
	[config setFontWidth:width];
}

//_______________________________________________________________________________

-(void)setFont:(NSString*)font
{
	TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];
	
	[config setFont:font];
}

//_______________________________________________________________________________

-(void) popViewController
{
  if ([[[self topViewController] view] respondsToSelector:@selector(prepareToPop)])
  {
    [[[self topViewController] view] performSelector:@selector(prepareToPop)];
  }
    
	if ([[self topViewController] view] == fontView)
	{
		[terminalView fontChanged];
		if (terminalIndex < [[application textviews] count])
			[[[application textviews] objectAtIndex:terminalIndex] resetFont];
	}
	
	[super popViewController];
}

//_______________________________________________________________________________

-(void) pushViewControllerWithView:(id)view navigationTitle:(NSString*)title
{
  if ([view respondsToSelector:@selector(prepareToPush)])
  {
    [view performSelector:@selector(prepareToPush)];
  }  
  
  [super pushViewControllerWithView:view navigationTitle:title];
}

//_______________________________________________________________________________

-(void)_didFinishPoppingViewController
{
  UIView * topView = [[self topViewController] view];
  if (topView == menuView)
  {
    [menuView removeFromSuperview];
    [menuView autorelease];
    menuView = nil;
  }
  else if (topView == terminalView)
  {
    [terminalView removeFromSuperview];
    [terminalView autorelease];
    terminalView = nil;
  }
  else if (topView == gestureView)
  {
    [gestureView removeFromSuperview];
    [gestureView autorelease];
    gestureView = nil;
  }
  else if (topView == longSwipeView)
  {
    [longSwipeView removeFromSuperview];
    [longSwipeView autorelease];
    longSwipeView = nil;
  }
  else if (topView == twoFingerSwipeView)
  {
    [twoFingerSwipeView removeFromSuperview];
    [twoFingerSwipeView autorelease];
    twoFingerSwipeView = nil;
  }
  
	[super _didFinishPoppingViewController];
	
	if ([[self topViewController] view] == settingsView)
	{
		[[self navigationBar] showLeftButton:@"Done" withStyle: 5 rightButton:nil withStyle: 0];
	}	
}

//_______________________________________________________________________________

-(void)_didFinishPushingViewController
{
	[super _didFinishPushingViewController];
	
	if ([[self topViewController] view] == fontView)
	{
		TerminalConfig * config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:terminalIndex];

		[fontView selectFont:[config font] size:[config fontSize] width:[config fontWidth]];
	}
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation ColorTableCell

- (void) drawRect:(CGRect)rect
{
  CGContextRef context = UICurrentContext();
	CGContextSetFillColorWithColor(context, CGColorWithRGBAColor(color));
  CGContextSetStrokeColorWithColor(context, colorWithRGBA(0.0,0.0,0.0,0.8));
    
  UIBezierPath * path = [UIBezierPath roundedRectBezierPath:CGRectMake(10, 2, rect.size.width-20, rect.size.height-4)
                                         withRoundedCorners:0xffffffff
                                           withCornerRadius:7.0f];	 

  [path fill];
  [path stroke];
  
  CGContextFlush(context);  
}

//_______________________________________________________________________________

- (void) setColor:(RGBAColor)color_
{
  color = color_;
  [self setNeedsDisplay];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PreferencesGroups

//_______________________________________________________________________________

- (id) init 
{
	if ((self = [super init])) 
	{
		groups = [[NSMutableArray arrayWithCapacity:1] retain];
	}
	
	return self;
}

//_______________________________________________________________________________

- (void) addGroup: (PreferencesGroup*) group 
{
	[groups addObject: group];
}

//_______________________________________________________________________________

- (PreferencesGroup*) groupAtIndex: (int) index 
{
	return [groups objectAtIndex: index];
}

//_______________________________________________________________________________

- (int) groups 
{
	return [groups count];
}

//_______________________________________________________________________________

- (int) numberOfGroupsInPreferencesTable: (UIPreferencesTable*)table 
{
	return [groups count];
}

//_______________________________________________________________________________

- (int) preferencesTable: (UIPreferencesTable*) table numberOfRowsInGroup: (int) group 
{
	return [[groups objectAtIndex: group] rows];
}

//_______________________________________________________________________________

- (UIPreferencesTableCell*) preferencesTable: (UIPreferencesTable*)table cellForGroup: (int)group  
{
	return [[groups objectAtIndex: group] title];
} 

//_______________________________________________________________________________

- (float) preferencesTable: (UIPreferencesTable*)table heightForRow: (int)row inGroup: (int)group withProposedHeight: (float)proposed  
{
	if (row == -1)
	{
		return [[groups objectAtIndex: group] titleHeight];
	} 
	else 
	{
    UIPreferencesTableCell * cell = [[groups objectAtIndex: group] row:row];
    if ([cell respondsToSelector:@selector(getHeight)])
    {
      float height;
      SEL sel = @selector(getHeight);
      NSMethodSignature * sig = [[cell class] instanceMethodSignatureForSelector:sel];
      NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
      [invocation setTarget:cell];
      [invocation setSelector:sel];
      [invocation invoke];
      [invocation getReturnValue:&height];
      return height;      
    }
    else
      return proposed;
	}
}

//_______________________________________________________________________________

- (UIPreferencesTableCell*) preferencesTable: (UIPreferencesTable*)table cellForRow: (int)row inGroup: (int)group 
{
	return [[groups objectAtIndex: group] row: row];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PreferencesGroup

@synthesize title;
@synthesize titleHeight;

//_______________________________________________________________________________

+ (id) groupWithTitle: (NSString*) title icon: (UIImage*) icon 
{
	return [[PreferencesGroup alloc] initWithTitle: title icon: icon];
}

//_______________________________________________________________________________

- (id) initWithTitle: (NSString*) title_ icon: (UIImage*) icon 
{
	if ((self = [super init])) 
	{
		title = [[[UIPreferencesTableCell alloc] init] retain];
		[title setTitle: title_];
		if (icon)  [title setIcon: icon];			
		titleHeight = ([title_ length] > 0) ? 40.0f : 14.0f;		
		cells = [[NSMutableArray arrayWithCapacity:1] retain];
	}
	
	return self;
}

//_______________________________________________________________________________

- (void) removeCell:(id)cell
{
	if ([cells containsObject:cell])
		[cells removeObject:cell];
}

//_______________________________________________________________________________

- (void) addCell: (id) cell 
{
	if (![cells containsObject:cell])
		[cells addObject:cell];
}

//_______________________________________________________________________________

- (id) addSwitch: (NSString*) label 
{
	return [self addSwitch:label on:NO target:nil action:nil];
}

//_______________________________________________________________________________

- (id) addSwitch: (NSString*)label target:(id)target action:(SEL)action
{
	return [self addSwitch:label on:NO target:target action:action];
}

//_______________________________________________________________________________

- (id) addSwitch: (NSString*) label on: (BOOL) on 
{
	return [self addSwitch:label on:on target:nil action:nil];
}

//_______________________________________________________________________________

- (id) addSwitch:(NSString*)label on:(BOOL)on target:(id)target action:(SEL)action
{
	UIPreferencesControlTableCell* cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setShowSelection:NO];
	UISwitchControl * sw = [[UISwitchControl alloc] initWithFrame: CGRectMake(206.0f, 9.0f, 96.0f, 48.0f)];
	[sw setValue: (on ? 1.0f : 0.0f)];
	[sw addTarget:target action:action forEvents:64];
	[cell setControl:sw];	
	[cells addObject: cell];
	return cell;
}

//_______________________________________________________________________________

- (id) addMenuSwitch: (NSString*)label target:(id)target action:(SEL)action
{
	UIPreferencesControlTableCell* cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setShowSelection:NO];
	UISwitchControl * sw = [[UISwitchControl alloc] initWithFrame: CGRectMake(206.0f, 9.0f, 96.0f, 48.0f)];
	[sw setValue:0.0f];
	[sw addTarget:target action:action forEvents:64];
	[cell setControl:sw];	
	[cells addObject: cell];
	return cell;
}

//_______________________________________________________________________________

- (id) addIntValueSlider:(NSString*)label range:(NSRange)range target:(id)target action:(SEL)action
{
	UIPreferencesControlTableCell* cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setShowSelection:NO];
	UISliderControl * sc = [[UISliderControl alloc] initWithFrame: CGRectMake(100.0f, 1.0f, 200.0f, 40.0f)];
	[sc addTarget:target action:action forEvents:7|64];
	
	[sc setAllowsTickMarkValuesOnly:YES];
	[sc setNumberOfTickMarks:range.length+1];
	[sc setMinValue:range.location];
	[sc setMaxValue:NSMaxRange(range)];
	[sc setValue:range.location];
	[sc setShowValue:YES];
	[sc setContinuous:NO];
	
	[cell setControl:sc];	
	[cells addObject: cell];
	return cell;
}

//_______________________________________________________________________________

- (id) addFloatValueSlider: (NSString*)label minValue:(float)minValue maxValue:(float)maxValue target:(id)target action:(SEL)action
{
	UIPreferencesControlTableCell* cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setShowSelection:NO];
	UISliderControl * sc = [[UISliderControl alloc] initWithFrame: CGRectMake(100.0f, 1.0f, 200.0f, 40.0f)];
	[sc addTarget:target action:action forEvents:7|64];
	
	[sc setAllowsTickMarkValuesOnly:NO];
	[sc setMinValue:minValue];
	[sc setMaxValue:maxValue];
	[sc setValue:minValue];
	[sc setShowValue:YES];
	[sc setContinuous:YES];
	
	[cell setControl:sc];	
	[cells addObject: cell];
	return cell;
}

//_______________________________________________________________________________

-(id) addPageButton: (NSString*) label
{
	return [self addPageButton:label value:nil];
}

//_______________________________________________________________________________

-(id) addPageButton: (NSString*) label value:(NSString*)value
{
	UIPreferencesTextTableCell * cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setValue: value];
	[cell setShowDisclosure:YES];
	[cell setDisclosureClickable: NO];
	[cell setDisclosureStyle: 2];
	[[cell textField] setEnabled:NO];
	[cells addObject: cell];
	
	[[cell textField] setTapDelegate:[PreferencesController sharedInstance]];
	[cell setTapDelegate:[PreferencesController sharedInstance]];
	
	return cell;
}

//_______________________________________________________________________________

-(id) addColorPageButton:(NSString*)label colorRef:(RGBAColorRef)color
{
	UIPreferencesTextTableCell * cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setShowDisclosure:YES];
	[cell setDisclosureClickable: NO];
	[cell setDisclosureStyle: 2];
	[[cell textField] setEnabled:NO];
	[cells addObject: cell];
	
	ColorButton * colorButton = [[ColorButton alloc] initWithFrame:CGRectMake(240,3,39,39) colorRef:color];
	[cell addSubview:colorButton];
	
	[colorButton setTapDelegate:colorButton];
	[[cell textField] setTapDelegate:colorButton];
	[cell setTapDelegate:colorButton];
	
	return colorButton;
}

//_______________________________________________________________________________

-(id) addValueField:(NSString*)label value:(NSString*)value
{
	UIPreferencesTextTableCell * cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
	[cell setValue: value];
	[[cell textField] setEnabled:NO];
	[[cell textField] setHorizontallyCenterText:YES];
	[cells addObject: cell];	
	return cell;
}

//_______________________________________________________________________________

-(id) addTextField:(NSString*)label value:(NSString*)value
{
	UIPreferencesTextTableCell * cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
	[cell setTitle: label];
  [cell setValue: value];
	[[cell textField] setHorizontallyCenterText:NO];
	[[cell textField] setEnabled:YES];
	[cells addObject: cell];	
	return cell;
}

//_______________________________________________________________________________

-(id) addColorField
{
	ColorTableCell * cell = [[ColorTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
  [cell setDrawsBackground:NO];
	[cells addObject: cell];
	return cell;
}

//_______________________________________________________________________________

- (int) rows 
{
	return [cells count];
}

//_______________________________________________________________________________

- (UIPreferencesTableCell*) row: (int) row 
{
	if (row == -1) 
	{
		return nil;
	} 
	else 
	{
		return [cells objectAtIndex:row];
	}
}

//_______________________________________________________________________________

- (NSString*) stringValueForRow: (int) row 
{
	UIPreferencesTextTableCell* cell = (UIPreferencesTextTableCell*)[self row: row];
	return [[cell textField] text];
}

//_______________________________________________________________________________

- (BOOL) boolValueForRow: (int) row 
{
	UIPreferencesControlTableCell * cell = (UIPreferencesControlTableCell*)[self row: row];
	UISwitchControl * sw = [cell control];
	return [sw value] == 1.0f;
}

@end


