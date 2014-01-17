//
//	htmls.m
//	readability
//
//	Created by Jan on 24.03.12.
//	Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "htmls.h"

#import "NSString+Counting.h"
#import "NSXMLNode+HTMLUtilities.h"
#import "NSString+JXRemoving.h"
#import "NSString+ReplaceExtensions.h"

NSString * normalizeEntities(NSString *curTitle);
NSString * normTitle(NSString *title);

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


NSString * normalizeEntities(NSString *curTitle) {
	NSDictionary *entities = @{@"—": @"-", // EM DASH
							  @"–": @"-", // EN DASH
							  @"&mdash;": @"-",
							  @"&ndash;": @"-",
							  @" ": @" ", // NO-BREAK SPACE
							  @"«": @"\"",
							  @"»": @"\"",
							  @"&quot;": @"\""};
	
	return [curTitle stringByReplacingStringsFromDictionary:entities];
}

NSString * normTitle(NSString *title) {
	return normalizeEntities([title jx_stringByCollapsingAndRemovingSurroundingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:@" "]);
}

NSString * getTitleInDocument(NSXMLDocument *doc) {
	NSString *title = nil;
	NSArray *titleNodes = [doc tagsWithNames:@"title", nil];
	
	if (titleNodes.count == 0)	return @"[no-title]";
	
	title = [titleNodes[0] lxmlText];
    
    return normTitle(title);
}

void addMatch(NSMutableSet *collection, NSString *text, NSString *orig) {
	text = normTitle(text);
	
	if ((text.length >= 15) && [text countOfSubstringsWithOptions:NSStringEnumerationByWords isAtLeast:2]) {
		NSString *textWithoutQuotes = [text stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
		NSString *origWithoutQuotes = [orig stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, orig.length)];
		
		if (([origWithoutQuotes rangeOfString:textWithoutQuotes 
						 options:NSLiteralSearch 
							 range:NSMakeRange(0, origWithoutQuotes.length)].location) != NSNotFound) {
			[collection addObject:text];
		}

	}
}

NSString * shortenTitleInDocument(NSXMLDocument *doc) {
	static BOOL firstRun = YES;
	static NSArray *cssXPaths = nil;
	static NSArray *delimiters = nil;
	
	if (firstRun) {
		NSArray *cssSelectors = @[@"#title", @"#head", @"#heading", @".pageTitle", @".newsTitle", @".title", @".head", @".heading", @".contentheading", @".smallHeaderRed"];
		
		NSMutableArray *cssXPathsMutable = [[NSMutableArray alloc] initWithCapacity:cssSelectors.count];
		
		for (NSString *selector in cssSelectors) {
			[cssXPathsMutable addObject:lxmlCSSToXPath(selector)];
		}
		
		cssXPaths = [cssXPathsMutable copy];
		
		delimiters = @[@" | ", @" - ", @" :: ", @" / "];
		
		firstRun = NO;
	}
	
	NSString *title = nil;
	NSArray *titleNodes = [doc tagsWithNames:@"title", nil];
	
	if (titleNodes.count == 0)	return @"";
	
	title = [titleNodes[0] lxmlText];
	
	NSString *orig;
	title = orig = normTitle(title);

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
									 @[candidatesAscendingDescriptor]];
		
		
		title = [sortedCandidates lastObject];
	}
	else {
		NSArray *parts;
		BOOL didBreak = NO;
		
		for (NSString *delimiter in delimiters) {
			if ([title rangeOfString:delimiter 
							 options:NSLiteralSearch].location != NSNotFound) {
				parts = [orig componentsSeparatedByString:delimiter];
				
				NSString *titleCandidate;
				if (titleCandidate = parts[0], 
					[titleCandidate countOfSubstringsWithOptions:NSStringEnumerationByWords isAtLeast:4]) {
					title = titleCandidate;
					didBreak = YES;
					break;
				}
				else if (titleCandidate = [parts lastObject], 
						 [titleCandidate countOfSubstringsWithOptions:NSStringEnumerationByWords isAtLeast:4]) {
					title = titleCandidate;
					didBreak = YES;
					break;
				}
			}
		}
		
		if (didBreak == NO) {
			NSString *delimiter = @": ";
			if ([title rangeOfString:delimiter 
							 options:NSLiteralSearch].location != NSNotFound) {
				parts = [orig componentsSeparatedByString:delimiter];
				
				NSString *titleCandidate;
				if (titleCandidate = [parts lastObject], 
					[titleCandidate countOfSubstringsWithOptions:NSStringEnumerationByWords isAtLeast:4]) {
					title = [parts lastObject];
				}
				else {
					title = [[parts subarrayWithRange:NSMakeRange(1, (parts.count - 1))] componentsJoinedByString:delimiter];
				}
			}
		}
	}

	NSUInteger titleLength = title.length;
	if ( !((15 < titleLength) && (titleLength < 150)) )	 return orig;

	return title;
}
