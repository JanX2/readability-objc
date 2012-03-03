//
//  JXReadablilityDocument.m
//  readability
//
//  Created by Jan on 25.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "JXReadabilityDocument.h"

#import "NSXMLNode+HTMLUtilities.h"

#define TEXT_LENGTH_THRESHOLD	25
#define RETRY_LENGTH			250

NSString * const	unlikelyCandidates = 	@"combx|comment|community|disqus|extra|foot|header|menu|remark|rss|shoutbox|sidebar|sponsor|ad-break|agegate|pagination|pager|popup|tweet|twitter";
NSString * const	okMaybeItsACandidate = 	@"and|article|body|column|main|shadow";
NSString * const	positiveNames =			@"article|body|content|entry|hentry|main|page|pagination|post|text|blog|story";
NSString * const	negativeNames =			@"combx|comment|com-|contact|foot|footer|footnote|masthead|media|meta|outbrain|promo|related|scroll|shoutbox|sidebar|sponsor|shopping|tags|tool|widget";
NSString * const	divToPElements =		@"<(a|blockquote|dl|div|img|ol|p|pre|table|ul)";

@interface JXReadabilityDocument (Private)
- (NSArray *)tagsIn:(NSXMLNode *)node withNames:(NSString *)firstTagName, ... NS_REQUIRES_NIL_TERMINATION;
@end

@implementation JXReadabilityDocument

@synthesize input;
@synthesize html;

@synthesize options;

- (id)initWithXMLDocument:(NSXMLDocument *)aDoc;
{
	self = [super init];
	
	if (self) {
		self.html = aDoc;
		self.options = [NSMutableDictionary dictionary];
		
		unlikelyCandidatesRe = 		[[NSRegularExpression alloc] initWithPattern:unlikelyCandidates		 options:0 error:NULL];
		okMaybeItsACandidateRe = 	[[NSRegularExpression alloc] initWithPattern:okMaybeItsACandidate	 options:0 error:NULL];
		positiveRe = 				[[NSRegularExpression alloc] initWithPattern:positiveNames			 options:0 error:NULL];
		negativeRe = 				[[NSRegularExpression alloc] initWithPattern:negativeNames			 options:0 error:NULL];
		divToPElementsRe = 			[[NSRegularExpression alloc] initWithPattern:divToPElements			 options:0 error:NULL];
	}
	
	return self;
}

- (void)dealloc
{
	self.html = nil;
	self.options = nil;
	
	[unlikelyCandidatesRe release];
	[okMaybeItsACandidateRe release];
	[positiveRe release];
	[negativeRe release];
	[divToPElementsRe release];
	
	[super dealloc];
}


- (NSArray *)tagsIn:(NSXMLNode *)node withNames:(NSString *)firstTagName, ...
{
    NSMutableArray *tags = [NSMutableArray array];
	
	va_list tag_names;
	va_start (tag_names, firstTagName);
    for (NSString *tagName = firstTagName; tagName != nil; tagName = va_arg(tag_names, NSString *)) {
        [tags addObjectsFromArray:[node nodesForXPath:[NSString stringWithFormat:@".//%@", tagName] error:NULL]];
    }
	va_end (tag_names);
	
	return tags;
}

- (void)removeUnlikelyCandidates
{
	NSXMLNode *elem = self.html;
	
	do {
		if ([elem kind] == NSXMLElementKind) {
			NSString *s = [NSString stringWithFormat:@"%@ %@", 
						   [elem cssNamesForAttributeWithName:@"class"], 
						   [elem cssNamesForAttributeWithName:@"id"]];
			//[self debug:s];
			
			NSRange sRange = NSMakeRange(0, [s length]);
			
			if (([unlikelyCandidatesRe rangeOfFirstMatchInString:s options:0 range:sRange].location != NSNotFound) 
				&& ([okMaybeItsACandidateRe rangeOfFirstMatchInString:s options:0 range:sRange].location == NSNotFound)
				&& ![elem.name isEqualToString:@"body"]) {
				//[self debug:[NSString stringWithFormat:@"Removing unlikely candidate - %@", elem]];
				[elem detach];
			}
		}
		
	} while ((elem = [elem nextNode]) != nil);
}

- (void)transformMisusedDivsIntoParagraphs
{
	NSArray *nodes;
	
	NSString *s;
	
	nodes = [self tagsIn:self.html withNames:@"div", nil];
	for (NSXMLNode *elem in nodes) {
		// Transform <div>s that do not contain other block elements into <p>s
		s = [elem XMLString];
		if ([divToPElementsRe rangeOfFirstMatchInString:s
												options:0 
												  range:NSMakeRange(0, [s length])].location == NSNotFound) {
			//[self debug:[NSString stringWithFormat:@"Altering %@ to p", elem]];
			[elem setName:@"p"];
			//NSLog(@"Fixed element %@", elem);
		}
	}
	
	NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSXMLElement *p;
	
	nodes = [self tagsIn:self.html withNames:@"div", nil];
	for (NSXMLElement *elem in nodes) { // div tags always are elements
		s = [elem stringValue];
		if (([s length] != 0) 
			&& ([[s stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] length] != 0)) { // using -ws_isBlankString would be faster
			
			p = [NSXMLNode elementWithName:@"p" 
							   stringValue:s];
			
			[elem setStringValue:@""];
			[elem insertChild:p atIndex:0];
			//NSLog(@"Appended %@ to %@", p, elem);
		}
		
		[[elem children] enumerateObjectsWithOptions:NSEnumerationReverse 
										  usingBlock:^(id obj, NSUInteger pos, BOOL *stop) {
											  NSXMLNode *child = obj;
											  NSString *childTailString;
											  NSXMLNode *tailNode;
											  NSXMLElement *paragraph;
											  
											  if ([child kind] != NSXMLTextKind) {
												  
												  tailNode = [child nextSibling];
												  if ((tailNode == nil) || ([tailNode kind] != NSXMLTextKind)) {
													  childTailString = @"";
												  } else {
													  childTailString = [tailNode stringValue];
												  }
												  
												  if (([childTailString length] != 0) 
													  && ([[childTailString stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] length] != 0)) { // using -ws_isBlankString would be faster
													  
													  paragraph = [NSXMLNode elementWithName:@"p" 
																				 stringValue:childTailString];
													  
													  [tailNode detach]; // We could get [tailNode index] and insert there after detaching
													  [elem insertChild:paragraph atIndex:(pos + 1)];
													  //NSLog(@"Appended %@ to %@", p, elem);
												  }
												  
											  }
											  
											  if ([[child name] isEqualToString:@"br"]) {
												  [child detach];
												  //NSLog(@"Dropped <br> at %@", elem);
											  }
										  }];
		
	}	
}

- (NSXMLDocument *)summaryXMLDocument;
{
	if (self.html == nil)  return nil;
	
	BOOL ruthless = YES;
	while (1) {
		//[self _html:YES];
		
		NSArray *nodes;
		
		// Remove comment nodes
		NSXMLNode *thisNode = self.html;
		NSXMLNode *prevNode = nil;
		while (thisNode != nil) {
			if ((prevNode != nil) && ([prevNode kind] == NSXMLCommentKind)) {
				[prevNode detach];
			}
			prevNode = thisNode;
			thisNode = [thisNode nextNode];
		}
		
		// Delete non-content nodes
		nodes = [self tagsIn:self.html withNames:@"noscript", @"script", @"style", nil];
		for (NSXMLNode *i in nodes) {
			[i detach];
		}
		
		// Add readability CSS ID to body tag
		nodes = [self tagsIn:self.html withNames:@"body", nil];
		for (NSXMLNode *i in nodes) {
			[i addCSSName:@"readabilityBody" toAttributeWithName:@"id"];
		}
		
		if (ruthless)  [self removeUnlikelyCandidates];
		
		[self transformMisusedDivsIntoParagraphs];
		
		return self.html;
	}
}

@end
