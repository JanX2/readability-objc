//
//  htmls.m
//  readability
//
//  Created by Jan on 24.03.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "htmls.h"

#import "NSString+Counting.h"
#import "NSXMLNode+HTMLUtilities.h"

NSString * lxmlCSSToXPath(NSString *cssExpr) {
	NSString *prefix = @"descendant-or-self::";
	
	static BOOL firstRun = YES;
	static NSRegularExpression *elRe = nil;
	static NSRegularExpression *idRe = nil;
	static NSRegularExpression *classRe = nil;
	
	if (firstRun) {
		elRe = 		[[NSRegularExpression alloc] initWithPattern:@"^(\\w+)\\s*$" 			options:0 error:NULL];
		idRe = 		[[NSRegularExpression alloc] initWithPattern:@"^(\\w*)#(\\w+)\\s*$"		options:0 error:NULL];
		classRe = 	[[NSRegularExpression alloc] initWithPattern:@"^(\\w*)\\.(\\w+)\\s*$" 	options:0 error:NULL];
		firstRun = NO;
	}
	
	NSString *expr = nil;
	
	NSRange cssExprRange = NSMakeRange(0, cssExpr.length);
	NSTextCheckingResult *match;
	
#warning Check if -firstMatchInString returns nil for no match!! 
	match = [elRe firstMatchInString:cssExpr options:0 range:cssExprRange];
	if (match != nil) {
		return [NSString stringWithFormat:@"%@%@", prefix, [cssExpr substringWithRange:[match rangeAtIndex:1]]];
	}
	
	match = [idRe firstMatchInString:cssExpr options:0 range:cssExprRange];
	if (match != nil) {
		NSRange match1Range = [match rangeAtIndex:1];
		NSString *match1 = ((match1Range.location == NSNotFound) || (match1Range.length == 0)) ? @"*" : [cssExpr substringWithRange:match1Range];
		NSString *match2 = [cssExpr substringWithRange:[match rangeAtIndex:2]];
		NSString *result = [NSString stringWithFormat:@"%@%@[@id = '%@']", prefix, match1, match2];
		
		return result;
	}
	
	match = [classRe firstMatchInString:cssExpr options:0 range:cssExprRange];
	if (match != nil) {
		NSRange match1Range = [match rangeAtIndex:1];
		NSString *match1 = ((match1Range.location == NSNotFound) || (match1Range.length == 0)) ? @"*" : [cssExpr substringWithRange:match1Range];
		NSString *match2 = [cssExpr substringWithRange:[match rangeAtIndex:2]];
		NSString *result = [NSString stringWithFormat:@"%@%@[contains(concat(' ', normalize-space(@class), ' '), ' %@ ')]", prefix, match1, match2];
		
		return result;
	}
	
    return expr;
}


void addMatch(NSMutableSet *collection, NSString *text, NSString *orig) {
    //text = normTitle(text);
    if ((text.length >= 15) && [text countOfSubstringsWithOptions:NSStringEnumerationByWords atLeast:2]) {
		//NSString *textWithoutQuotes = [text stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
		//NSString *origWithoutQuotes = [orig stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, orig.length)];
		
		if (([orig rangeOfString:text 
						 options:NSLiteralSearch 
						   range:NSMakeRange(0, orig.length)].location) != NSNotFound) {
			[collection addObject:text];
		}

    }
}

NSString * shortenTitleInDocument(NSXMLDocument *doc) {
    NSString *title = nil;
	NSArray *titleNodes = [doc tagsWithNames:@"title", nil];
	
    if (titleNodes.count == 0)  return @"";
	
	title = [[titleNodes objectAtIndex:0] lxmlText];
    
    NSString *orig;
    title = orig;// = normTitle(title);

#warning How does NSXML treat HTML entities? 

    NSMutableSet *candidates = [NSMutableSet set];

    for (NSXMLElement *e in [doc tagsWithNames:@"h1", @"h2", @"h3", nil]) {
		NSString *eText;
		
		eText = e.lxmlText;
		if (eText) {
			addMatch(candidates, eText, orig);
		}
		
		eText = e.stringValue;
		if (eText) {
			addMatch(candidates, eText, orig);
		}
	}

	static BOOL firstRun = YES;
	static NSArray *cssXPaths = nil;

	if (firstRun) {
		NSArray *cssSelectors = [NSArray arrayWithObjects:@"#title", @"#head", @"#heading", @".pageTitle", @".newsTitle", @".title", @".head", @".heading", @".contentheading", @".smallHeaderRed", nil];
		
		NSMutableArray *cssXPathsMutable = [[NSMutableArray alloc] initWithCapacity:cssSelectors.count];
		
		for (NSString *selector in cssSelectors) {
			[cssXPathsMutable addObject:lxmlCSSToXPath(selector)];
		}
		
		cssXPaths = [cssXPathsMutable copy];
		[cssXPathsMutable release];
		
		firstRun = NO;
	}
	
    for (NSString *item in cssXPaths) {
		NSArray *foundNodes = [doc nodesForXPath:item 
										   error:NULL];
		
        for (NSXMLElement *e in foundNodes) {
			NSString *eText;
			
			eText = e.lxmlText;
			if (eText) {
				addMatch(candidates, eText, orig);
			}
			
			eText = e.stringValue;
			if (eText) {
				addMatch(candidates, eText, orig);
			}
		}
	}
                
    if (candidates) {
		NSSortDescriptor *candidatesAscendingDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"length" 
																						ascending:YES];
		
		NSArray *sortedCandidates = [[candidates allObjects] sortedArrayUsingDescriptors:
									 [NSArray arrayWithObject:candidatesAscendingDescriptor]];
		
		
        title = [sortedCandidates lastObject];
	}
    else {
        for (delimiter in [NSArray arrayWithObjects:@" | ", @" - ", @" :: ", @" / ", nil]) {
            if (delimiter in title) {
                parts = orig.split(delimiter);
                if (len(parts[0].split()) >= 4) {
                    title = parts[0];
                    break;
                    }
                else if (len(parts[-1].split()) >= 4) {
                    title = parts[-1];
                    break;
                }
                }
        else {
            if (@": " in title) {
                parts = orig.split(@": ");
                if (len(parts[-1].split()) >= 4) {
                    title = parts[-1];
                    }
                else {
                    title = orig.split(@": ", 1)[1];
                    }
                    }
                    }
		}
	}

	NSUInteger titleLength = title.length;
    if ( !((15 < titleLength) && (titleLength < 150)) )  return orig;

    return title;
}
