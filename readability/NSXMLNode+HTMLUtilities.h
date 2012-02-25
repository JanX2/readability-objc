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

@end
