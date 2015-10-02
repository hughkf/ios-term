//
//  Settings.m
//  Terminal

#import "Settings.h"
#import "Constants.h"
#import "MobileTerminal.h"
#import "Menu.h"
#import "ColorMap.h"
#import <Foundation/NSUserDefaults.h>

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation TerminalConfig

//_______________________________________________________________________________

- (id)init
{
  self = [super init];
  
  autosize = YES;
  width = 45;
  fontSize = 12;
  fontWidth = 0.6f;
  font = @"CourierNewBold";
  args = @"";
  
  return self;
}

//_______________________________________________________________________________

- (NSString*)fontDescription
{
  return [NSString stringWithFormat:@"%@ %d", font, fontSize];
}

//_______________________________________________________________________________

- (NSString*) font { return font; }
- (void) setFont: (NSString*)str
{
  if (font != str)
  {
    [font release];
    font = [str copy];
  }
}

//_______________________________________________________________________________

- (NSString*) args { return args; }
- (void) setArgs: (NSString*)str
{
  if (args != str)
  {
    [args release];
    args = [str copy];
  }
}

- (RGBAColor*) colors {
  return colors;
}

//_______________________________________________________________________________

@synthesize width;
@synthesize autosize;
@synthesize fontSize;
@synthesize fontWidth;
@dynamic font;
@dynamic args;
@dynamic colors;

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation Settings

//_______________________________________________________________________________

+ (Settings*) sharedInstance
{
  static Settings * instance = nil;
  if (instance == nil) instance = [[Settings alloc] init];
  return instance;
}

//_______________________________________________________________________________

- (id)init
{
  self = [super init];

  terminalConfigs = [NSArray arrayWithObjects:
                     [[TerminalConfig alloc] init],
                     [[TerminalConfig alloc] init],
                     [[TerminalConfig alloc] init],
                     [[TerminalConfig alloc] init], nil];
  
  gestureFrameColor = RGBAColorMake(1.0f, 1.0f, 1.0f, 0.05f);
  multipleTerminals = NO;
  menu = nil; 
  swipeGestures = nil;
  arguments = @"";
  
  return self;
}

//_______________________________________________________________________________

@synthesize multipleTerminals;

//_______________________________________________________________________________

-(void) registerDefaults
{
  int i;
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary * d = [NSMutableDictionary dictionaryWithCapacity:2];
  [d setObject:[NSNumber numberWithBool:MULTIPLE_TERMINALS] forKey:@"multipleTerminals"];

  // menu buttons
      
  NSArray * menuArray = [NSArray arrayWithContentsOfFile:@"/Applications/Terminal.app/menu.plist"];
  if (menuArray == nil) menuArray = [[Menu create] getArray];
  [d setObject:menuArray forKey:@"menu"];
  
  // swipe gestures
  
  NSMutableDictionary * gestures = [NSMutableDictionary dictionaryWithCapacity:16];
  
  i = 0;
  while (DEFAULT_SWIPE_GESTURES[i][0])
  {
    [gestures setObject:DEFAULT_SWIPE_GESTURES[i][1] forKey:DEFAULT_SWIPE_GESTURES[i][0]];
    i++;
  }
  
  [d setObject:gestures forKey:@"swipeGestures"];
  
  // terminals
  
  NSMutableArray * tcs = [NSMutableArray arrayWithCapacity:MAXTERMINALS];
  for (i = 0; i < MAXTERMINALS; i++)
  {
    NSMutableDictionary * tc = [NSMutableDictionary dictionaryWithCapacity:10];    
    [tc setObject:[NSNumber numberWithBool:YES]   forKey:@"autosize"];
    [tc setObject:[NSNumber numberWithInt:45]     forKey:@"width"];
    [tc setObject:[NSNumber numberWithInt:12]     forKey:@"fontSize"];
    [tc setObject:[NSNumber numberWithFloat:0.6f] forKey:@"fontWidth"];
    [tc setObject:@"CourierNewBold" forKey:@"font"];
    [tc setObject:(i > 0 ? @"clear" : @"") forKey:@"args"];

    NSMutableArray * ca = [NSMutableArray arrayWithCapacity:NUM_TERMINAL_COLORS];
    NSArray * colorValues;

    switch (i) { // bg color
      case 1:  colorValues = RGBAColorToArray(RGBAColorMake(0.1, 0, 0, 1));  break;
      case 2:  colorValues = RGBAColorToArray(RGBAColorMake(0, 0, 0.1, 1));  break;
      case 3:  colorValues = RGBAColorToArray(RGBAColorMake(1, 1, 1, 1));   break;
      default: colorValues = RGBAColorToArray(RGBAColorMake(0, 0, 0, 1));    break;
    };
    [ca addObject:colorValues];
    
    switch (i) { // fg color
      case 3:   colorValues = RGBAColorToArray(RGBAColorMake(0, 0, 0, 1));  break; 
      default:  colorValues = RGBAColorToArray(RGBAColorMake(1, 1, 1, 1));  break;
    };    
    [ca addObject:colorValues]; 
    
    switch (i) { // bold color
      case 3:  colorValues = RGBAColorToArray(RGBAColorMake(0, 0, 0.5, 1)); break;
      default: colorValues = RGBAColorToArray(RGBAColorMake(1, 1, 0, 1));   break;
    };
    [ca addObject:colorValues]; 
    
    switch (i) { // cursor text
      case 3:  colorValues = RGBAColorToArray(RGBAColorMake(1, 1, 0, 1));   break;
      default: colorValues = RGBAColorToArray(RGBAColorMake(1, 0, 0, 1));   break;
    };
    [ca addObject:colorValues]; 
    
    switch (i) { // cursor color
      case 3:  colorValues = RGBAColorToArray(RGBAColorMake(0, 0, 0, 1));   break;
      default: colorValues = RGBAColorToArray(RGBAColorMake(1, 1, 0, 1));   break;
    };
    [ca addObject:colorValues]; 
    
    [tc setObject:ca forKey:@"colors"];
    [tcs addObject:tc];
  }
  [d setObject:tcs forKey:@"terminals"];
  
  NSArray * colorValues = RGBAColorToArray(RGBAColorMake(1, 1, 1, 0.05f));
  [d setObject:colorValues forKey:@"gestureFrameColor"];
    
  [defaults registerDefaults:d];  
}

//_______________________________________________________________________________

-(void) readUserDefaults
{
  int i, c;
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  NSArray * tcs = [defaults arrayForKey:@"terminals"];
    
  for (i = 0; i < MAXTERMINALS; i++)
  {
    TerminalConfig * config = [terminalConfigs objectAtIndex:i];
    NSDictionary * tc = [tcs objectAtIndex:i];
    config.autosize =   [[tc objectForKey:@"autosize"]  boolValue];
    config.width =      [[tc objectForKey:@"width"]     intValue];
    config.fontSize =   [[tc objectForKey:@"fontSize"]  intValue];
    config.fontWidth =  [[tc objectForKey:@"fontWidth"] floatValue];
    config.font =        [tc objectForKey:@"font"];
    config.args =        [tc objectForKey:@"args"];
    for (c = 0; c < NUM_TERMINAL_COLORS; c++)
    {
      config.colors[c] = RGBAColorMakeWithArray([[tc objectForKey:@"colors"] objectAtIndex:c]);
      [[ColorMap sharedInstance] setTerminalColor:CGColorWithRGBAColor(config.colors[c]) atIndex:c termid:i];
    }
  }

  multipleTerminals = MULTIPLE_TERMINALS && [defaults boolForKey:@"multipleTerminals"];
  menu = [[defaults arrayForKey:@"menu"] retain];
  swipeGestures = [[NSMutableDictionary dictionaryWithCapacity:24] retain];
  [swipeGestures setDictionary:[defaults objectForKey:@"swipeGestures"]];
  gestureFrameColor = RGBAColorMakeWithArray([defaults arrayForKey:@"gestureFrameColor"]);
}

//_______________________________________________________________________________

-(void) writeUserDefaults
{
  int i, c;
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray * tcs = [NSMutableArray arrayWithCapacity:MAXTERMINALS];

  for (i = 0; i < MAXTERMINALS; i++)
  {
    TerminalConfig * config = [terminalConfigs objectAtIndex:i];
    NSMutableDictionary * tc = [NSMutableDictionary dictionaryWithCapacity:10];    
    [tc setObject:[NSNumber numberWithBool:config.autosize] forKey:@"autosize"];
    [tc setObject:[NSNumber numberWithInt:config.width] forKey:@"width"];
    [tc setObject:[NSNumber numberWithInt:config.fontSize] forKey:@"fontSize"];
    [tc setObject:[NSNumber numberWithFloat:config.fontWidth] forKey:@"fontWidth"];
    [tc setObject:config.font forKey:@"font"];
    [tc setObject:config.args ? config.args : @"" forKey:@"args"];

    NSMutableArray * ca = [NSMutableArray arrayWithCapacity:NUM_TERMINAL_COLORS];
    NSArray * colorValues;

    for (c = 0; c < NUM_TERMINAL_COLORS; c++)
    {
      colorValues = RGBAColorToArray(config.colors[c]); 
      [ca addObject:colorValues]; 
    }
    
    [tc setObject:ca forKey:@"colors"];    
    [tcs addObject:tc];
  }  
  [defaults setObject:tcs forKey:@"terminals"];
  [defaults setBool:multipleTerminals forKey:@"multipleTerminals"];
  [defaults setObject:[[MobileTerminal menu] getArray] forKey:@"menu"];
  [defaults setObject:swipeGestures forKey:@"swipeGestures"];
  [defaults setObject:RGBAColorToArray(gestureFrameColor) forKey:@"gestureFrameColor"];
  [defaults synchronize];
  [[[MobileTerminal menu] getArray] writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Preferences/com.googlecode.mobileterminal.menu.plist"] atomically:YES];
}

//_______________________________________________________________________________

-(void) setCommand:(NSString*)command forGesture:(NSString*)zone
{
  [swipeGestures setObject:command forKey:zone];
}

//_______________________________________________________________________________

-(NSArray*)       terminalConfigs       { return terminalConfigs; }
-(NSArray*)       menu                  { return menu; }
-(NSDictionary*)  swipeGestures         { return swipeGestures; }
-(RGBAColor)      gestureFrameColor     { return gestureFrameColor; }
-(RGBAColorRef)   gestureFrameColorRef  { return &gestureFrameColor; }
-(NSString*)      arguments             { return arguments; }

//_______________________________________________________________________________

- (void) setArguments: (NSString*)str
{
  if (arguments != str)
  {
    [arguments release];
    arguments = [str copy];
  }
}

@end
