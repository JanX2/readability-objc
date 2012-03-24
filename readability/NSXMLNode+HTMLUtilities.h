//
//  NSXMLNode+HTMLUtilities.h
//  readability
//
//  Created by Jan on 26.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const		tagNameXPath;

@interface NSXMLNode (HTMLUtilities)

- (NSArray *)tagsWithNames:(NSString *)firstTagName, ... NS_REQUIRES_NIL_TERMINATION;
- (NSArray *)reverseTagsWithNames:(NSString *)firstTagName, ... NS_REQUIRES_NIL_TERMINATION;

- (void)addCSSName:(NSString *)cssName toAttributeWithName:(NSString *)attributeName;

- (NSString *)cssNamesForAttributeWithName:(NSString *)attributeName;
#if 0
- (NSArray *)cssNamesSetForAttributeWithName:(NSString *)attributeName;
- (NSArray *)cssNamesForAttributeWithName:(NSString *)attributeName;
#endif

- (NSString *)lxmlText;
- (NSXMLNode *)lxmlTextNode;
- (NSXMLNode *)lxmlTailNode;

- (NSString *)readabilityDescription;
- (NSString *)readabilityDescriptionWithDepth:(NSUInteger)depth;

@end
