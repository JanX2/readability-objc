//
//  NSXMLNode+HTMLUtilities.h
//  readability
//
//  Created by Jan on 26.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSXMLNode (HTMLUtilities)

- (void)addCSSName:(NSString *)cssName toAttributeWithName:(NSString *)attributeName;

- (NSString *)cssNamesForAttributeWithName:(NSString *)attributeName;
#if 0
- (NSArray *)cssNamesSetForAttributeWithName:(NSString *)attributeName;
- (NSArray *)cssNamesForAttributeWithName:(NSString *)attributeName;
#endif

- (NSString *)lxmlText;
- (NSXMLNode *)lxmlTailNode;

- (NSString *)readabilityDescription;
- (NSString *)readabilityDescriptionWithDepth:(NSUInteger)depth;

@end
