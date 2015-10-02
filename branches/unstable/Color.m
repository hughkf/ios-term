//
//  Color.m
//  Terminal

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "Color.h"

//_______________________________________________________________________________

RGBAColor RGBAColorMake (float r, float g, float b, float a)
{
	RGBAColor c;
	c.r = r; c.g = g; c.b = b; c.a = a;
	return c;
}

//_______________________________________________________________________________

RGBAColor RGBAColorMakeWithArray(NSArray * array)
{
	return RGBAColorMake(MIN(MAX(0, [[array objectAtIndex:0] floatValue]), 1), 
											 MIN(MAX(0, [[array objectAtIndex:1] floatValue]), 1),
											 MIN(MAX(0, [[array objectAtIndex:2] floatValue]), 1),
											 MIN(MAX(0, [[array objectAtIndex:3] floatValue]), 1));
}

//_______________________________________________________________________________

NSArray * RGBAColorToArray(RGBAColor c)
{
	return [NSArray arrayWithObjects:	[NSNumber numberWithFloat:c.r],
          [NSNumber numberWithFloat:MIN(MAX(0, c.g), 1)],
          [NSNumber numberWithFloat:MIN(MAX(0, c.b), 1)],
          [NSNumber numberWithFloat:MIN(MAX(0, c.a), 1)],
          nil];
}

//_______________________________________________________________________________

CGColorRef colorWithRGB(float red, float green, float blue)
{
  return colorWithRGBA(red, green, blue, 1);
}

//_______________________________________________________________________________

CGColorRef colorWithRGBA(float red, float green, float blue, float alpha)
{
	float rgba[4] = { MIN(MAX(0, red),   1), 
                    MIN(MAX(0, green), 1), 
                    MIN(MAX(0, blue),  1), 
                    MIN(MAX(0, alpha), 1) };
  
	CGColorSpaceRef rgbColorSpace = (CGColorSpaceRef)[(id)CGColorSpaceCreateDeviceRGB() autorelease];
	CGColorRef color = (CGColorRef)[(id)CGColorCreate(rgbColorSpace, rgba) autorelease];
	return color;	
}

//_______________________________________________________________________________

CGColorRef CGColorWithRGBAColor(RGBAColor c)
{
	return colorWithRGBA(c.r, c.g, c.b, c.a);
}

//_______________________________________________________________________________
