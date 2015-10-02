//
//  Color.h
//  Terminal

//_______________________________________________________________________________

typedef struct {
	float r, g, b, a;
} RGBAColor;

typedef RGBAColor * RGBAColorRef;

CGColorRef colorWithRGB (float red, float green, float blue);
CGColorRef colorWithRGBA(float red, float green, float blue, float alpha);
CGColorRef CGColorWithRGBAColor(RGBAColor c);
RGBAColor RGBAColorMake (float r, float g, float b, float a);
RGBAColor RGBAColorMakeWithArray (NSArray * array);
NSArray * RGBAColorToArray (RGBAColor c);

