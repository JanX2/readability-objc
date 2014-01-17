//
//  NSString+ReplaceExtensions.m
//  readability
//
//  Created by Georg Fritzsche on 17.09.10.
//  http://stackoverflow.com/questions/3733980/replace-multiple-groups-of-characters-in-an-nsstring
//

#import "NSString+ReplaceExtensions.h"

@implementation NSString (ReplaceExtensions)

- (NSString *)stringByReplacingStringsFromDictionary:(NSDictionary *)dict;
{
	NSMutableString *string = [self mutableCopy];
	
	for (NSString *target in dict) {
		[string replaceOccurrencesOfString:target 
								withString:dict[target] 
								   options:0 
									 range:NSMakeRange(0, [string length])];
	}
	
	return [string autorelease];
}

@end
