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


NSString * const	newlinePlusSurroundingwhitespace =		@"\\s*\n\\s*";
NSString * const	tabRun =								@"[ \t]{2,}";


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
		
		whitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
		
		unlikelyCandidatesRe = 		[[NSRegularExpression alloc] initWithPattern:unlikelyCandidates		 options:0 error:NULL];
		okMaybeItsACandidateRe = 	[[NSRegularExpression alloc] initWithPattern:okMaybeItsACandidate	 options:0 error:NULL];
		positiveRe = 				[[NSRegularExpression alloc] initWithPattern:positiveNames			 options:0 error:NULL];
		negativeRe = 				[[NSRegularExpression alloc] initWithPattern:negativeNames			 options:0 error:NULL];
		divToPElementsRe = 			[[NSRegularExpression alloc] initWithPattern:divToPElements			 options:0 error:NULL];
		
		newlinePlusSurroundingwhitespaceRe = 
		[[NSRegularExpression alloc] initWithPattern:newlinePlusSurroundingwhitespace
											 options:0 
											   error:NULL];
		tabRunRe = [[NSRegularExpression alloc] initWithPattern:tabRun 
														options:0 
														  error:NULL];
	}
	
	return self;
}

- (void)dealloc
{
	self.html = nil;
	self.options = nil;
	
	[whitespaceAndNewlineCharacterSet release];
	
	[unlikelyCandidatesRe release];
	[okMaybeItsACandidateRe release];
	[positiveRe release];
	[negativeRe release];
	[divToPElementsRe release];
	
	[newlinePlusSurroundingwhitespaceRe release];
	[tabRunRe release];
	
	[super dealloc];
}


- (NSArray *)tagsIn:(NSXMLNode *)node withNames:(NSString *)firstTagName, ...
{
    NSMutableArray *tags = [NSMutableArray array];
	
	va_list tag_names;
	va_start (tag_names, firstTagName);
	// Original XPath: @".//%@". Alternative XPath: @".//*[matches(name(),'%@','i')]"
    for (NSString *tagName = firstTagName; tagName != nil; tagName = va_arg(tag_names, NSString *)) {
        [tags addObjectsFromArray:[node nodesForXPath:[NSString stringWithFormat:@".//*[lower-case(name())='%@']", tagName] error:NULL]];
    }
	va_end (tag_names);
	
	return tags;
}

- (void)debug:(id)a
{
	if ([(NSNumber *)[self.options objectForKey:@"debug"] boolValue])  NSLog(@"%@", a);
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

- (NSString *)clean:(NSString *)_text
{
	NSMutableString *text = [_text mutableCopy];
	
	[newlinePlusSurroundingwhitespaceRe replaceMatchesInString:text 
													   options:0 
														 range:NSMakeRange(0, [text length]) 
												  withTemplate:@"\n"];
	
	[tabRunRe replaceMatchesInString:text 
							 options:0 
							   range:NSMakeRange(0, [text length]) 
						withTemplate:@" "];
	
	CFStringTrimWhitespace((CFMutableStringRef)text);
	
	return [text autorelease];
}

- (NSUInteger)textLength:(NSXMLElement *)i
{
	NSString *s = [i stringValue];
	NSString *cleanS = (s != nil) ? [self clean:s] : @"";
	return [cleanS length];
}

- (float)classWeight:(NSXMLElement *)e
{
	NSXMLNode *attribute;
	
	float weight = 0;
	
	if ((attribute = [e attributeForName:@"class"]) != nil) {
		NSString *s = [attribute stringValue];
		NSRange sRange = NSMakeRange(0, [s length]);
		
		if ([negativeRe rangeOfFirstMatchInString:s options:0 range:sRange].location != NSNotFound)  weight -= 25;
		
		if ([positiveRe rangeOfFirstMatchInString:s options:0 range:sRange].location != NSNotFound)  weight += 25;
	}
	
	if ((attribute = [e attributeForName:@"id"]) != nil) {
		NSString *s = [attribute stringValue];
		NSRange sRange = NSMakeRange(0, [s length]);
		
		if ([negativeRe rangeOfFirstMatchInString:s options:0 range:sRange].location != NSNotFound)  weight -= 25;
		
		if ([positiveRe rangeOfFirstMatchInString:s options:0 range:sRange].location != NSNotFound)  weight += 25;
	}
	
	return weight;
}

- (NSMutableDictionary *)scoreNode:(NSXMLElement *)elem
{
	static BOOL firstRun = YES;
	static NSSet *preTDBlockquote = nil;
	static NSSet *addressEtc = nil;
	static NSSet *headlines = nil;
	
	if (firstRun) {
		preTDBlockquote = [[NSSet alloc] initWithObjects:@"pre", @"td", @"blockquote", nil];
		addressEtc = [[NSSet alloc] initWithObjects:@"address", @"ol", @"ul", @"dl", @"dd", @"dt", @"li", @"form", nil];
		headlines = [[NSSet alloc] initWithObjects:@"h1", @"h2", @"h3", @"h4", @"h5", @"h6", @"th", nil];
		firstRun = NO;
	}
	
	float contentScore = [self classWeight:elem];
	NSString *name = [elem.name lowercaseString];
	if ([name isEqualToString:@"div"]) {
		contentScore += 5;
	}
	else if ([preTDBlockquote containsObject:name]) {
		contentScore += 3;
	}
	else if ([addressEtc containsObject:name]) {
		contentScore -= 3;
	}
	else if ([headlines containsObject:name]) {
		contentScore -= 5;
	}
	
	return [NSMutableDictionary dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithFloat:contentScore], @"contentScore", 
			elem, @"elem", 
			nil];
}

- (float)getLinkDensity:(NSXMLElement *)elem
{
	NSUInteger linkLength = 0;
	for (NSXMLNode *i in [elem nodesForXPath:@".//a" error:NULL]) {
		linkLength += [[i stringValue] length];
		//if len(elem.findall(".//div") or elem.findall(".//p")):
		//	linkLength = linkLength
	}
	NSUInteger totalLength = [self textLength:elem];
	return (float)linkLength / MAX(totalLength, 1);
}

- (NSDictionary *)scoreParagraphs
{
	NSNumber *minLength = [self.options objectForKey:@"minTextLength"];	
	NSUInteger minLen = (minLength != nil) ? [minLength unsignedIntegerValue] : TEXT_LENGTH_THRESHOLD;
	
	NSMutableDictionary *candidates = [NSMutableDictionary dictionary];
	
	//[self debug:[self tagsIn:self.html withNames:@"div", nil]];
	
	NSXMLElement *parentNode, *grandParentNode; // parents have to be elements
	NSString *elemTextContent, *innerText;
	NSUInteger innerTextLen;

	NSMutableArray *ordered = [NSMutableArray array];
	for (NSXMLElement *elem in [self tagsIn:self.html withNames:@"p", @"pre", @"td", nil]) {
		parentNode = (NSXMLElement *)[elem parent];
		if (parentNode == nil)  continue;
		grandParentNode = (NSXMLElement *)[parentNode parent];
		
		elemTextContent = [elem stringValue];
		innerText = (elemTextContent != nil) ? [self clean:elemTextContent] : @"";
		innerTextLen = [innerText length];
		
		// If this paragraph is less than 25 characters, don't even count it.
		if (innerTextLen < minLen)  continue;

		if ([candidates objectForKey:parentNode] == nil) { 
			[candidates setObject:[self scoreNode:parentNode] forKey:parentNode];
			[ordered addObject:parentNode];
		}
		
		if ((grandParentNode != nil) 
			&& ([candidates objectForKey:grandParentNode] == nil)) {
			[candidates setObject:[self scoreNode:grandParentNode] forKey:grandParentNode];
			[ordered addObject:grandParentNode];
		}

		float contentScore = 1;
		contentScore += [[innerText componentsSeparatedByString:@","] count]; // CHANGEME: count the "," directly
		contentScore += MIN((innerTextLen / 100), 3);
		//if elem not in candidates:
		//	candidates[elem] = self.scoreNode(elem)
				
		//WTF? candidates[elem]['contentScore'] += contentScore
		float tempScore;
		NSMutableDictionary *scoreDict;
		scoreDict = [candidates objectForKey:parentNode];
		tempScore = [[scoreDict objectForKey:@"contentScore"] floatValue] + contentScore;
		[scoreDict setObject:[NSNumber numberWithFloat:tempScore] forKey:@"contentScore"];
		if (grandParentNode != nil) {
			scoreDict = [candidates objectForKey:grandParentNode];
			tempScore = [[scoreDict objectForKey:@"contentScore"] floatValue] + contentScore / 2.0;
			[scoreDict setObject:[NSNumber numberWithFloat:tempScore] forKey:@"contentScore"];
		}
	}
	
	// Scale the final candidates score based on link density. Good content should have a
	// relatively small link density (5% or less) and be mostly unaffected by this operation.
	NSMutableDictionary *candidate;
	float ld;
	float score;
	
	for (NSXMLElement *elem in ordered) {
		candidate = [candidates objectForKey:elem];
		ld = [self getLinkDensity:elem];
		score = [[candidate objectForKey:@"contentScore"] floatValue];
		//[self debug:[NSString stringWithFormat:@"Candid: %6.3f %s link density %.3f -> %6.3f", score, [elem description], ld, score*(1-ld)]];
		score *= (1 - ld);
		[candidate setObject:[NSNumber numberWithFloat:score] forKey:@"contentScore"];
	}
	
	return candidates;
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
		
		NSDictionary *candidates = [self scoreParagraphs];
		//NSLog(@"%@", candidates);
		
		return self.html;
	}
}

@end
