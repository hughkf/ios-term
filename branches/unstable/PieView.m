#import "PieView.h"
#import "Color.h"
#import "Menu.h"
#import "Settings.h"
#import "Constants.h"
#import "Log.h"

//_______________________________________________________________________________
//_______________________________________________________________________________

bool CGFontGetGlyphsForUnichars(CGFontRef, unichar[], CGGlyph[], size_t);
extern CGFontRef CGContextGetFont(CGContextRef);
extern CGFontRef CGFontCreateWithFontName(CFStringRef name);

@implementation PieButton

//_______________________________________________________________________________

- (id)initWithFrame:(CGRect)frame identifier:(int)identifier_
{
  self = [super initWithTitle:@""];
  
  identifier = identifier_;
  
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *imagePath = [bundle pathForResource:[NSString stringWithFormat:(identifier % 2 ? @"pie_gray%d" : @"pie_white%d"), (identifier+1)] ofType: @"png"];
  UIImage * image = [[UIImage alloc] initWithContentsOfFile: imagePath];
  [self setImage:image forState:0];
  
  imagePath = [bundle pathForResource: [NSString stringWithFormat:@"pie_blue%d",(identifier+1)] ofType: @"png"];
  image = [[UIImage alloc] initWithContentsOfFile: imagePath];
  [self setImage:image forState:1];
  [self setImage:image forState:4];
  
  [self setDrawContentsCentered:YES];	
  [self setAutosizesToFit:NO];
  [self setEnabled: YES];		
  [self setOpaque:NO];
  
  if (identifier % 2) {
      // gray
      [self setTitleColor:colorWithRGBA(1,1,1,1) forState:0]; // normal
      [self setShadowColor:colorWithRGBA(.25,.25,.25,1) forState:0]; // normal
      _shadowOffset = CGSizeMake(0.0, 1.0);
  } else {
      // white
      [self setTitleColor:colorWithRGBA(0,0,0,1) forState:0]; // normal
      [self setShadowColor:colorWithRGBA(1,1,1,1) forState:0]; // normal
      _shadowOffset = CGSizeMake(0.0, -1.0);
  }
  [self setTitleColor:colorWithRGBA(1,1,1,1) forState:1]; // pressed
  [self setTitleColor:colorWithRGBA(1,1,1,1) forState:4]; // selected  
  [self setShadowColor:colorWithRGBA(0.1,0.1,0.7,1) forState:1]; // pressed
  [self setShadowColor:colorWithRGBA(0.1,0.1,0.7,1) forState:4]; // selected

  [self setOrigin:frame.origin];
  
  unichar dotChar[1] = {0x2022};
  dot = [[NSString stringWithCharacters:dotChar length:1] retain];  
  
  return self;
}  

//_______________________________________________________________________________

- (void) drawTitleAtPoint:(CGPoint)point width:(float)width
{  
  CGContextRef context = UICurrentContext();
  CGContextSaveGState(context);
  
  float height = 14.0f;

  NSString *fontName = @"HelveticaBold";
  CGContextSelectFont(context, [fontName cString], height, kCGEncodingMacRoman);
  CGFontRef font = CGContextGetFont(context);

  NSString * text = [self title];
  size_t len = [text length];

  CGContextSetTextDrawingMode(context, kCGTextInvisible); 
  unichar chars[12] = {0};
  CGGlyph glyphs[12] = {0};

  int numChars = 12;
  float textWidth = 100;
  while (textWidth > 50 && numChars > 4)
  {
    len = len > numChars-1 ? numChars-1 : len;
    [text getCharacters:chars range: NSMakeRange(0, len)];
    
    CGFontGetGlyphsForUnichars(font, chars, glyphs, len);
    
    CGContextSetTextPosition(context, 0, 0);    
    CGContextShowGlyphs(context, glyphs, len);
    CGPoint end = CGContextGetTextPosition(context);
    
    textWidth = end.x;
    numChars--;
  }
  
  CGAffineTransform scale = CGAffineTransformMake(1, 0, 0, -1, 0, 1.0);
  float rot[8] = {M_PI/2, M_PI/4, 0, -M_PI/4, M_PI/2, M_PI/4,  0, -M_PI/4};
  
  CGAffineTransform transform = scale;
  
  if ((identifier % 4) != 0 || textWidth > 26)
    transform = CGAffineTransformRotate(scale, rot[identifier]);
  
  CGContextSetTextMatrix(context, transform);

  CGContextSetFont(context, font);
  CGContextSetFontSize(context, height); 
    
  CGContextSetTextDrawingMode(context, kCGTextFill); 
  CGContextSetFillColorWithColor(context, [self titleColorForState:[self state]]);
  //if (!([self state] & kPressed))
  CGContextSetShadowWithColor(context, (!([self state] & kPressed)) ? _shadowOffset : CGSizeMake(0.0f, 1.0f), 0.0f, [self shadowColorForState:[self state]]);
  
  CGPoint center = CGPointMake(-0.5f*textWidth, -0.25*height);
  CGPoint p = CGPointApplyAffineTransform(center, transform);
  CGContextShowGlyphsAtPoint(context, 0.5*[self bounds].size.width + p.x, 0.5*[self bounds].size.height + p.y, glyphs, len);
  
  CGContextRestoreGState(context);  
  CGContextSetTextMatrix(context, CGAffineTransformIdentity);
}

//_______________________________________________________________________________

-(NSString*) dotStringWithCommand:(NSString*)cmd
{
  return [NSString stringWithFormat:@"%@%@", dot, cmd];
}

//_______________________________________________________________________________

- (NSString*) command { return command; }
- (void) setCommand:(NSString*)command_
{
  [command release];
  command = [command_ copy];
  [self setTitle:[self commandString]];
}

//_______________________________________________________________________________

-(NSString*) commandString
{
  NSMutableString * str = [NSMutableString stringWithCapacity:64];
  [str setString:[self command]];
  int i = 0;
  while (STRG_CTRL_MAP[i].str)
  {
    int toLength = 0;
    while (STRG_CTRL_MAP[i].chars[toLength]) toLength++;
    NSString * from = [self dotStringWithCommand:STRG_CTRL_MAP[i].str];
    NSString * to = [NSString stringWithCharacters:STRG_CTRL_MAP[i].chars length:toLength];
    
    [str replaceOccurrencesOfString:to withString:from options:0 range:NSMakeRange(0, [str length])];
    
    i++;
  }
  return str;  
}

//_______________________________________________________________________________

-(void) setCommandString:(NSString*)cmdString
{
  NSMutableString * cmd = [NSMutableString stringWithCapacity:64];
  [cmd setString:cmdString];
  
  int i = 0;
  while (STRG_CTRL_MAP[i].str)
  {
    int toLength = 0;
    while (STRG_CTRL_MAP[i].chars[toLength]) toLength++;
    NSString * from = [self dotStringWithCommand:STRG_CTRL_MAP[i].str];
    NSString * to = [NSString stringWithCharacters:STRG_CTRL_MAP[i].chars length:toLength];
    
    [cmd replaceOccurrencesOfString:from withString:to options:0 range:NSMakeRange(0, [cmd length])];
    
    i++;
  }
  [self setCommand:cmd];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PieView

//_______________________________________________________________________________

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];

  buttons = [[NSMutableArray arrayWithCapacity:8] retain];
  
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *imagePath = [bundle pathForResource: @"pie_back" ofType: @"png"];
  pie_back = [[UIImage alloc] initWithContentsOfFile: imagePath];
  int i;
  
  for (i = 0; i < 8; i++) 
  {
    const float x[]  = {   5.0,  12.0,  69.0, 126.0, 161.0, 126.0,  69.0,  12.0};
    const float y[]  = {  73.0,  15.0,   7.0,  15.0,  73.0, 129.0, 165.0, 129.0};
    
    PieButton * button = [[PieButton alloc] initWithFrame:CGRectMake(x[i],y[i],0,0) identifier:i];
    [buttons addObject:button];
    [button addTarget:self action:@selector(buttonPressed:) forEvents:64];
    [self addSubview:button];
  }

  return self;
}

//_______________________________________________________________________________

- (void) buttonPressed:(PieButton*)button
{
  if (button != activeButton)
  {
    if (activeButton) [activeButton setSelected:NO];
    activeButton = button;
    [activeButton setSelected:YES];
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(pieButtonPressed:)])
      [[self delegate] performSelector:@selector(pieButtonPressed:) withObject:activeButton];
  }
}

//_______________________________________________________________________________

- (void) deselectButton:(PieButton*) button
{
  [button setSelected:NO];
  if (button == activeButton) activeButton = nil;
}

//_______________________________________________________________________________

- (void) selectButton:(PieButton*) button
{
  if (activeButton) [activeButton setSelected:NO];
  [button setSelected:YES];
  activeButton = button;
}

//_______________________________________________________________________________

- (PieButton*) buttonAtIndex:(int)index
{
  return [[self buttons] objectAtIndex:index];
}

//_______________________________________________________________________________

- (void)drawRect:(CGRect)rect
{
  [pie_back compositeToPoint: CGPointMake(0.0f, 0.0f) operation: 2];
}

//_______________________________________________________________________________

- (BOOL)isOpaque { return NO; }
- (BOOL)ignoresMouseEvents { return NO; }
- (void) setDelegate:(id)delegate_ { delegate = delegate_; }
- (id) delegate { return delegate; }
- (NSArray*) buttons { return buttons; }
@end
