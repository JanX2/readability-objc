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
	if ([self isKindOfClass:[NSXMLElement class]]) {
		NSXMLElement *selfElement = (NSXMLElement *)self;
		NSXMLNode *attribute = [selfElement attributeForName:attributeName];
		if (attribute == nil) {
			attribute = [NSXMLNode attributeWithName:attributeName 
										 stringValue:cssName];
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

@end
