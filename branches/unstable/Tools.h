//
//  Tools.h
//  Terminal

#import <Foundation/Foundation.h>

//_______________________________________________________________________________

BOOL writeImageToPNG (CGImageRef image, NSString * filePath);

//_______________________________________________________________________________

@interface NSArray (NSFastEnumeration)

- (int) countByEnumeratingWithState:(void*)state objects:(id *)stackbuf count:(int)len;

@end

//_______________________________________________________________________________

@interface NSString (MobileTerminalExtensions)

- (int) indexOfSubstring:(NSString*)substring;
- (BOOL) hasSubstring:(NSString*)substring;

@end

//_______________________________________________________________________________

@interface NSMutableString (MobileTerminalExtensions)

- (void) removeSubstring:(NSString*)substring;

@end
