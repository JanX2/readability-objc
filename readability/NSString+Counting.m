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

- (NSUInteger)countSubstringsWithOptions:(NSStringEnumerationOptions)opts;
{
	if (self.length == 0)  return 0;
	
	__block NSUInteger count = 0;
	
	[self enumerateSubstringsInRange:NSMakeRange(0, self.length) 
							 options:(opts | NSStringEnumerationSubstringNotRequired) 
						  usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
							  count++;
						  }];
	
	return count;
}

- (BOOL)countOfSubstringsWithOptions:(NSStringEnumerationOptions)opts atLeast:(NSUInteger)lowerBound;
{
	if (self.length == 0)  return 0;
	
	__block NSUInteger count = 0;
	
	[self enumerateSubstringsInRange:NSMakeRange(0, self.length) 
							 options:(opts | NSStringEnumerationSubstringNotRequired) 
						  usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
							  count++;
							  if (count == lowerBound)  *stop = YES;
						  }];
	
	return (count >= lowerBound);
}

@end
