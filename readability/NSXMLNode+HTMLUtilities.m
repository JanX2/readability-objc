//
//  NSXMLNode+HTMLUtilities.m
//  readability
//
//  Created by Jan on 26.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "NSXMLNode+HTMLUtilities.h"


// Original XPath: @".//%@". Alternative XPath: @".//*[matches(name(),'%@','i')]"
NSString * const	tagNameXPath = @".//*[lower-case(name())='%@']";


@implementation NSXMLNode (HTMLUtilities)

- (NSArray *)tagsWithNames:(NSString *)firstTagName, ... ;
{
    NSMutableArray *tags = [NSMutableArray array];
	
	va_list tag_names;
	va_start (tag_names, firstTagName);
    for (NSString *tagName = firstTagName; tagName != nil; tagName = va_arg(tag_names, NSString *)) {
		NSArray *foundNodes = [self nodesForXPath:[NSString stringWithFormat:tagNameXPath, tagName] 
											error:NULL];
		//foundNodes = [[foundNodes reverseObjectEnumerator] allObjects];
		[tags addObjectsFromArray:foundNodes];
    }
	va_end (tag_names);
	
	return tags;
}

- (NSArray *)reverseTagsWithNames:(NSString *)firstTagName, ... ;
{
    NSMutableArray *tags = [NSMutableArray array];
	
	va_list tag_names;
	va_start (tag_names, firstTagName);
    for (NSString *tagName = firstTagName; tagName != nil; tagName = va_arg(tag_names, NSString *)) {
		NSArray *foundNodes = [self nodesForXPath:[NSString stringWithFormat:tagNameXPath, tagName] 
											error:NULL];
		foundNodes = [[foundNodes reverseObjectEnumerator] allObjects];
		[tags addObjectsFromArray:foundNodes];
    }
	va_end (tag_names);
	
	return tags;
}


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


- (NSString *)lxmlText;
{
	NSString *s = nil;
	
	if (([self childCount] > 0)) {
		NSXMLNode *child = [self childAtIndex:0];
		if ([child kind] == NSXMLTextKind) {
			s = [child stringValue];
		}
	}
	
	return s;
}

- (NSXMLNode *)lxmlTextNode;
{
	if (([self childCount] > 0)) {
		NSXMLNode *child = [self childAtIndex:0];
		if ([child kind] == NSXMLTextKind) {
			return child;
		}
	}
	
	return nil;
}

- (NSXMLNode *)lxmlTailNode;
{
	if ([self kind] != NSXMLTextKind) {
		NSXMLNode *tailNode = [self nextSibling];
		
		if ((tailNode == nil) || ([tailNode kind] != NSXMLTextKind)) {
			return nil;
		} else {
			return tailNode;
		}
	}
	else {
		return nil;
	}
}


- (NSString *)readabilityDescription;
{
	return [self readabilityDescriptionWithDepth:1];
}
	
- (NSString *)readabilityDescriptionWithDepth:(NSUInteger)depth;
{
	NSString *selfName = self.name;
	if (selfName == nil) {
		NSString *kinds[] = {
			@"NSXMLInvalidKind,", 
			@"NSXMLDocumentKind,", 
			@"NSXMLElementKind,", 
			@"NSXMLAttributeKind,", 
			@"NSXMLNamespaceKind,", 
			@"NSXMLProcessingInstructionKind,", 
			@"NSXMLCommentKind,", 
			@"NSXMLTextKind,", 
			@"NSXMLDTDKind,", 
			@"NSXMLEntityDeclarationKind,", 
			@"NSXMLAttributeDeclarationKind,", 
			@"NSXMLElementDeclarationKind,", 
			@"NSXMLNotationDeclarationKind"
		};
		return [NSString stringWithFormat:@"[%@]", kinds[(int)self.kind]];
	}

	NSMutableString *name = [NSMutableString string];
	
	NSString *ids = [self cssNamesForAttributeWithName:@"id"];
	NSString *classes = [self cssNamesForAttributeWithName:@"class"];
	
	if (ids != nil) {
		[name appendFormat:@"#%@", 
		 [ids stringByReplacingOccurrencesOfString:@" " 
										withString:@"#" 
										   options:NSLiteralSearch 
											 range:NSMakeRange(0, [ids length])]];
	}
	
	if (classes != nil) {
		[name appendFormat:@".%@", 
		 [classes stringByReplacingOccurrencesOfString:@" " 
											withString:@"." 
											   options:NSLiteralSearch 
												 range:NSMakeRange(0, [classes length])]];
	}
	
	if (([name length] == 0) || ![selfName isEqualToString:@"div"]) {
		[name insertString:selfName atIndex:0];
	}
	
	if (depth > 0) { 
		NSXMLNode *selfParent = [self parent];
		if (selfParent != nil) {
			[name appendFormat:@" - %@", 
			 [selfParent readabilityDescriptionWithDepth:(depth-1)]
			 ];
		}
	}
	
	return name;
}

@end
