//
//  NSString+Counting.m
//  readability
//
//  Created by Jan on 05.03.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "NSString+Counting.h"

@implementation NSString (Counting)

- (NSUInteger)countOccurancesOfString:(NSString *)needle;
{
	if ([self length] == 0)  return 0;
	
	NSUInteger count = 0;

	NSScanner *scanner = [[NSScanner alloc] initWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	
	while ([scanner isAtEnd] == NO) {
		if ([scanner scanString:needle intoString:NULL])  count++;
		
		// Scan up to the start of the next occurence of needle or to the end of the scanned string.
		[scanner scanUpToString:needle intoString:NULL];
	}
	
	[scanner release];
	
	return count;
}
@end
