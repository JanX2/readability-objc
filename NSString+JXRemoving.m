//
//  NSString+JXRemoving.m
//  string-splitter
//
//  Created by Jan on 11.01.12.
//  Copyright 2012 geheimwerk.de. All rights reserved.
//

#import "NSString+JXRemoving.h"

// Based on OmniFoundation/NSString-OFReplacement

@implementation NSString (Removing)

- (NSString *)jx_stringByRemovingPrefix:(NSString *)prefix;
{
    NSRange aRange = [self rangeOfString:prefix options:NSAnchoredSearch];
    if ((aRange.length == 0) || (aRange.location != 0))
        return [[self retain] autorelease];
    return [self substringFromIndex:aRange.length];
}

- (NSString *)jx_stringByRemovingSuffix:(NSString *)suffix;
{
    if (![self hasSuffix:suffix])
        return [[self retain] autorelease];
    return [self substringToIndex:[self length] - [suffix length]];
}

- (NSString *)jx_stringByRemovingSurroundingWhitespace;
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)jx_stringByCollapsingAndRemovingSurroundingCharactersInSet:(NSCharacterSet *)collapsibleCharacterSet 
															  intoString:(NSString *)replacementString;
{
    NSUInteger length = [self length];
    if (length == 0)  return @""; // Trivial optimization
	
    NSScanner *stringScanner = [[NSScanner alloc] initWithString:self];
	[stringScanner setCharactersToBeSkipped:collapsibleCharacterSet];
    NSMutableString *collapsedString = [[NSMutableString alloc] initWithCapacity:length];
    BOOL firstSubstring = YES;
	NSString *nonWhitespaceSubstring;
    while ([stringScanner scanUpToCharactersFromSet:collapsibleCharacterSet intoString:&nonWhitespaceSubstring]) {
        if (nonWhitespaceSubstring) {
            if (firstSubstring) {
                firstSubstring = NO;
            } else {
                [collapsedString appendString:replacementString];
            }
            [collapsedString appendString:nonWhitespaceSubstring];
        }
    }
    [stringScanner release];
    return [collapsedString autorelease];
}


@end
