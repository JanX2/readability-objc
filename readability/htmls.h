//
//  htmls.h
//  readability
//
//  Created by Jan on 24.03.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * lxmlCSSToXPath(NSString *cssExpr);
void addMatch(NSMutableSet *collection, NSString *text, NSString *orig);
NSString * getTitleInDocument(NSXMLDocument *doc);
NSString * shortenTitleInDocument(NSXMLDocument *doc);
