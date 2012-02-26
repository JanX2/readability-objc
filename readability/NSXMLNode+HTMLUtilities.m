//
//  NSXMLNode+HTMLUtilities.m
//  readability
//
//  Created by Jan on 26.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "NSXMLNode+HTMLUtilities.h"

@implementation NSXMLNode (HTMLUtilities)

- (void)addCSSName:(NSString *)cssName toAttributeWithName:(NSString *)attributeName;
{
	if ([self kind] == NSXMLElementKind) {
		NSXMLElement *selfElement = (NSXMLElement *)self;
		NSXMLNode *attribute = [selfElement attributeForName:attributeName];
		if (attribute == nil) {
			attribute = [NSXMLNode attributeWithName:attributeName 
										 stringValue:cssName];
			[selfElement addAttribute:attribute];
		} else {
			NSString *attributeStringValue = [attribute stringValue];
			if ([attributeStringValue rangeOfString:cssName 
											options:NSLiteralSearch].location == NSNotFound) {
				[attribute setStringValue:[NSString stringWithFormat:@"%@ %@", 
										   attributeStringValue, 
										   cssName]
				 ];
			}
		}
	}
}

- (NSString *)cssNamesForAttributeWithName:(NSString *)attributeName;
{
	if ([self kind] == NSXMLElementKind) {
		NSXMLElement *selfElement = (NSXMLElement *)self;
		NSXMLNode *attribute = [selfElement attributeForName:attributeName];
		return [attribute stringValue];
	}
	
	return nil;
}

#if 0
- (NSSet *)cssNamesSetForAttributeWithName:(NSString *)attributeName;
{
	if ([self kind] == NSXMLElementKind) {
		NSXMLElement *selfElement = (NSXMLElement *)self;
		NSXMLNode *attribute = [selfElement attributeForName:attributeName];
		if (attribute == nil) {
			return nil;
		} else {
			NSArray *cssNames = [[attribute stringValue] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			NSMutableSet *cssNamesSet = [NSMutableSet setWithArray:cssNames];
			[cssNamesSet removeObject:@""];
			
			return cssNamesSet;
		}
	}
	
	return nil;
}

- (NSArray *)cssNamesForAttributeWithName:(NSString *)attributeName;
{
	if ([self kind] == NSXMLElementKind) {
		NSXMLElement *selfElement = (NSXMLElement *)self;
		NSXMLNode *attribute = [selfElement attributeForName:attributeName];
		if (attribute == nil) {
			return nil;
		} else {
			NSArray *cssNames = [[attribute stringValue] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			NSIndexSet *emptyStringIndexes = [cssNames indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
				if ([(NSString *)obj length] == 0) {
					return YES;
				}
				else {
					return NO;
				}
			}];
			
			if ([emptyStringIndexes count] > 0) {
				NSMutableArray *cssNamesMutable = [cssNames mutableCopy];
				[cssNamesMutable removeObjectsAtIndexes:emptyStringIndexes];
				return [cssNamesMutable autorelease];
			} else {
				return cssNames;
			}
			
		}
	}
	
	return nil;
}
#endif

@end
