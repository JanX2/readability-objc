//
//  JXReadablilityDocument.m
//  readability
//
//  Created by Jan on 25.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "JXReadabilityDocument.h"

#import "NSString+Counting.h"
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
NSString * const	sentenceEnd =							@"\\.( |$)";


// Original XPath: @".//%@". Alternative XPath: @".//*[matches(name(),'%@','i')]"
NSString * const	tagNameXPath = @".//*[lower-case(name())='%@']";


@interface HashableElement : NSObject <NSCopying> {
	NSXMLNode *_node;
}

@property (nonatomic, retain) NSXMLNode *node;

+ (id)elementForNode:(NSXMLNode *)aNode;
- (id)initWithNode:(NSXMLNode *)aNode;

@end


@interface JXReadabilityDocument (Private)
- (NSArray *)tagsIn:(NSXMLNode *)node withNames:(NSString *)firstTagName, ... NS_REQUIRES_NIL_TERMINATION;
@end

@implementation JXReadabilityDocument

@synthesize input;
@synthesize html;

@synthesize options;

- (id)initWithXMLDocument:(NSXMLDocument *)aDoc copyDocument:(BOOL)doCopy;
{
	if (doCopy) {
		return [self initWithXMLDocument:[[aDoc copy] autorelease]];
	} else {
		return [self initWithXMLDocument:aDoc];
	}
}

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
		sentenceEndRe = [[NSRegularExpression alloc] initWithPattern:sentenceEnd 
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
	[sentenceEndRe release];
	
	[super dealloc];
}


- (NSArray *)tagsIn:(NSXMLNode *)node withNames:(NSString *)firstTagName, ...
{
    NSMutableArray *tags = [NSMutableArray array];
	
	va_list tag_names;
	va_start (tag_names, firstTagName);
    for (NSString *tagName = firstTagName; tagName != nil; tagName = va_arg(tag_names, NSString *)) {
        [tags addObjectsFromArray:
		 [node nodesForXPath:[NSString stringWithFormat:tagNameXPath, tagName] 
					   error:NULL]
		 ];
    }
	va_end (tag_names);
	
	return tags;
}

- (NSArray *)reverseTagsIn:(NSXMLNode *)node withNames:(NSString *)firstTagName, ...
{
    NSMutableArray *tags = [NSMutableArray array];
	
	va_list tag_names;
	va_start (tag_names, firstTagName);
    for (NSString *tagName = firstTagName; tagName != nil; tagName = va_arg(tag_names, NSString *)) {
        [tags addObjectsFromArray:
		 [[[node nodesForXPath:[NSString stringWithFormat:tagNameXPath, tagName] 
						 error:NULL]
		   reverseObjectEnumerator] allObjects]
		];
    }
	va_end (tag_names);
	
	return tags;
}

- (void)debug:(id)a
{
	/*if ([(NSNumber *)[self.options objectForKey:@"debug"] boolValue])  */NSLog(@"%@", a);
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

- (NSUInteger)textLength:(NSXMLNode *)i
{
	if ([i kind] == NSXMLElementKind) {
		NSString *s = [i stringValue];
		NSString *cleanS = (s != nil) ? [self clean:s] : @"";
		return [cleanS length];
	}
	else {
		return 0;
	}
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

- (NSXMLDocument *)getArticleForCandidates:(NSDictionary *)candidates andBestCandidate:(NSDictionary *)bestCandidate
{
	// Now that we have the top candidate, look through its siblings for content that might also be related
	// Things like preambles, content split by ads that we removed, etc.

	float siblingScoreThreshold = MAX(10.0, ([[bestCandidate objectForKey:@"contentScore"] floatValue] * 0.2));
	NSXMLDocument *output = [[[NSXMLDocument alloc] initWithXMLString:@"<html><body /></html>" 
															 options:NSXMLDocumentTidyHTML 
															   error:NULL] autorelease];
	[output setDocumentContentKind:NSXMLDocumentXHTMLKind];
	NSXMLElement *htmlBody = [[output nodesForXPath:@"/html/body" 
											  error:NULL] objectAtIndex:0];
	NSXMLNode *bestElem = [bestCandidate objectForKey:@"elem"];
	
	BOOL append;
	NSDictionary *siblingScoreDict;
	HashableElement *siblingKey;
	for (NSXMLNode *sibling in [[bestElem parent] children]) {
		//if isinstance(sibling, NavigableString): continue#in lxml there no concept of simple text 
		append = NO; 
		
		if (sibling == bestElem)  append = YES;
		
		if (append == NO) {
			siblingKey = [HashableElement elementForNode:sibling];
			siblingScoreDict = [candidates objectForKey:siblingKey];
			if ((siblingScoreDict != nil) 
				&& ([[siblingScoreDict objectForKey:@"contentScore"] floatValue] >= siblingScoreThreshold)) {
				append = YES;
			}
		}
		
		if ((append == NO)
			&& [sibling.name isEqualToString:@"p"]
			&& ([sibling kind] == NSXMLElementKind)) {
			
			float linkDensity = [self getLinkDensity:(NSXMLElement *)sibling];
			NSString *nodeContent = [sibling stringValue];
			nodeContent = (nodeContent == nil) ? @"" : nodeContent;
			NSUInteger nodeLength = [nodeContent length];
			
			if ((nodeLength > 80) 
				&& (linkDensity < 0.25)) {
				append = YES;
			}
			else if ((nodeLength <= 80) 
					 && (linkDensity == 0.0) 
					 && ([sentenceEndRe rangeOfFirstMatchInString:nodeContent options:0 range:NSMakeRange(0, [nodeContent length])].location != NSNotFound)) {
				append = YES;
			}
		}
		
		if (append)  [htmlBody addChild:[[sibling copy] autorelease]];
	}				
	
	//if output is not None: 
	//	output.append(bestElem)

	return output;
	
}

- (NSDictionary *)selectBestCandidate:(NSDictionary *)candidates
{
	NSArray *allCandidates = [candidates allValues];
	if ([allCandidates count] == 0)  return nil;
	
	NSSortDescriptor *contentScoreDescendingDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"contentScore" 
																					   ascending:NO];
	
	NSArray *sortedCandidates = [allCandidates sortedArrayUsingDescriptors:
								 [NSArray arrayWithObject:contentScoreDescendingDescriptor]];
	
#if 0
	NSXMLElement *elem;
	NSArray *topFive = ([sortedCandidates count] >= 5) ? [sortedCandidates subarrayWithRange:NSMakeRange(0, 5)] : sortedCandidates;
	for (NSDictionary *candidate in topFive) {
		elem = [candidate objectForKey:@"elem"];
		[self debug:[NSString stringWithFormat:@"Top 5 : %6.3f %@", [candidate objectForKey:@"contentScore"], [elem description]]];
	}
#endif
	
	NSDictionary *bestCandidate = [sortedCandidates objectAtIndex:0];
	return bestCandidate;
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
	HashableElement *hashableElement;
	for (NSXMLElement *elem in [self tagsIn:self.html withNames:@"p", @"pre", @"td", nil]) {
		parentNode = (NSXMLElement *)[elem parent];
		if (parentNode == nil)  continue;
		grandParentNode = (NSXMLElement *)[parentNode parent];
		
		elemTextContent = [elem stringValue];
		innerText = (elemTextContent != nil) ? [self clean:elemTextContent] : @"";
		innerTextLen = [innerText length];
		
		// If this paragraph is less than 25 characters, don't even count it.
		if (innerTextLen < minLen)  continue;
		
		hashableElement = [HashableElement elementForNode:parentNode];
		if ([candidates objectForKey:hashableElement] == nil) { 
			[candidates setObject:[self scoreNode:parentNode] 
						   forKey:hashableElement];
			[ordered addObject:parentNode];
		}
		
		if (grandParentNode != nil) {
			hashableElement = [HashableElement elementForNode:grandParentNode];
			if ([candidates objectForKey:hashableElement] == nil) {
				[candidates setObject:[self scoreNode:grandParentNode] 
							   forKey:hashableElement];
				[ordered addObject:grandParentNode];
			}
		}

		float contentScore = 1.0;
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

NSUInteger sumCFArrayOfNSUInteger(CFArrayRef array);
NSUInteger sumCFArrayOfNSUInteger(CFArrayRef array) {
	NSUInteger siblingsSum = 0;
	
	CFIndex i, c = CFArrayGetCount(array);
	for (i = 0; i < c; i++) {
		siblingsSum += (NSUInteger)CFArrayGetValueAtIndex(array, i);
	}
	
	return siblingsSum;
}

- (NSXMLDocument *)sanitizeArticle:(NSXMLDocument *)node forCandidates:(NSDictionary *)candidates
{
	NSNumber *minTextLengthNum = [self.options objectForKey:@"minTextLength"];
	NSUInteger minLen = (minTextLengthNum != nil) ? [minTextLengthNum unsignedIntegerValue] : TEXT_LENGTH_THRESHOLD;
	for (NSXMLElement *header in [self tagsIn:node withNames:@"h1", @"h2", @"h3", @"h4", @"h5", @"h6", nil]) {
		if ([self classWeight:header] < 0 || [self getLinkDensity:header] > 0.33) { 
			[header detach];
		}
	}

	for (NSXMLElement *elem in [self tagsIn:node withNames:@"form", @"iframe", @"textarea", nil]) {
		[elem detach];
	}
	
	CFMutableDictionaryRef allowed = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL); // keys: HashableElement, values:raw BOOL
	
	NSDictionary *elDict;
	HashableElement *hashableEl;
	float weight;
	NSString *tag;
	float contentScore;
	CFIndex kindCount;
	NSArray *tagKinds = [NSArray arrayWithObjects:@"p", @"img", @"li", @"a", @"embed", @"input", nil];
	NSUInteger contentLength;
	float linkDensity;
	NSXMLNode *parentNode;
	NSDictionary *parentNodeDict;
	
	BOOL toRemove;
	NSString *reason;

	// Conditionally clean <table>s, <ul>s, and <div>s
	for (NSXMLElement *el in [self reverseTagsIn:node withNames:@"table", @"ul", @"div", nil]) {
		hashableEl = [HashableElement elementForNode:el];
		
		if (CFDictionaryContainsValue(allowed, hashableEl))  continue;
		
		weight = [self classWeight:el];
		
		elDict = [candidates objectForKey:hashableEl];
		if (elDict != nil) {
			contentScore = [[elDict objectForKey:@"contentScore"] floatValue];
			//print '!',el, '-> %6.3f' % contentScore
		}
		else {
			contentScore = 0;
		}
		
		tag = el.name;

		if ((weight + contentScore) < 0.0) {
			[self debug:[NSString stringWithFormat:@"Cleaned %@ with score %6.3f and weight %-3s",
						 el, contentScore, weight]];
			[el detach];
		}
		else if ([[el stringValue] countOccurancesOfString:@","] < 10) {
			CFMutableDictionaryRef counts = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL); // keys: NSString, values:raw CFIndex

			for (NSString *kind in tagKinds) {
				kindCount = (CFIndex)[[node nodesForXPath:[NSString stringWithFormat:tagNameXPath, kind] 
													error:NULL] count];
				CFDictionaryAddValue(counts, kind, (void *)kindCount);
			}
			
			if (CFDictionaryGetValueIfPresent(counts, @"li", (const void **)&kindCount)) {
				kindCount -= 100;
				CFDictionarySetValue(counts, @"li", (void *)kindCount);
			}

			contentLength = [self textLength:el]; // Count the text length excluding any surrounding whitespace
			linkDensity = [self getLinkDensity:el];
			
			parentNode = [el parent];
			if (parentNode != nil) {
				
				parentNodeDict = [candidates objectForKey:[HashableElement elementForNode:parentNode]];
				if (parentNodeDict != nil) {
					contentScore = [[parentNodeDict objectForKey:@"contentScore"] floatValue];
				}
				else {
					contentScore = 0.0;
				}
				
				//if parentNode is not None:
				//	pweight = self.classWeight(parentNode) + contentScore
				//	pname = describe(parentNode)
				//else:
				//	pweight = 0
				//	pname = "no parent"
				
				toRemove = NO;
				reason = @"";

#define countsFor(A)  (CFIndex)(CFDictionaryGetValue(counts, (A)))
				
				//if el.tag == 'div' and counts["img"] >= 1:
				//	continue
				if (countsFor(@"p") 
					&& (countsFor(@"img") > countsFor(@"p"))) {
					reason = [NSString stringWithFormat:@"too many images (%ld)", (long)countsFor(@"img")];
					toRemove = YES;
				}
				else if ((countsFor(@"li") > countsFor(@"p")) 
						 && ![tag isEqualToString:@"ul"] 
						 && ![tag isEqualToString:@"ol"]) {
					reason = @"more <li>s than <p>s";
					toRemove = YES;
				}
				else if (countsFor(@"input") > (countsFor(@"p") / 3)) {
					reason = @"less than 3x <p>s than <input>s";
					toRemove = YES;
				}
				else if ((contentLength < minLen) 
						 && ((countsFor(@"img") == 0) 
							 || (countsFor(@"img") > 2))) {
					reason = [NSString stringWithFormat:@"too short content length %lu without a single image", (unsigned long)contentLength];
					toRemove = YES;
				}
				else if (weight < 25 && linkDensity > 0.2) {
					reason = [NSString stringWithFormat:@"too many links %.3f for its weight %.0f", linkDensity, weight];
					toRemove = YES;
				}
				else if (weight >= 25 && linkDensity > 0.5) {
					reason = [NSString stringWithFormat:@"too many links %.3f for its weight %.0f", linkDensity, weight];
					toRemove = YES;
				}
				else if (((countsFor(@"embed") == 1) && (contentLength < 75)) || (countsFor(@"embed") > 1)) {
					reason = @"<embed>s with too short content length, or too many <embed>s";
					toRemove = YES;
				}

#undef countsFor

				//if el.tag == 'div' and counts['img'] >= 1 and toRemove:
				//	imgs = el.findall('.//img')
				//	validImg = False
				//	self.debug(tounicode(el))
				//	for img in imgs:
				//
				//		height = img.get('height')
				//		textLength = img.get('textLength')
				//		self.debug ("height %s textLength %s" %(repr(height), repr(textLength)))
				//		if toInt(height) >= 100 or toInt(textLength) >= 100:
				//			validImg = True
				//			self.debug("valid image" + tounicode(img))
				//			break
				//	if validImg:
				//		toRemove = False
				//		self.debug("Allowing %s" %el.textContent())
				//		for desnode in self.tags(el, "table", "ul", "div"):
				//			allowed[desnode] = True

				// Find x non empty preceding and succeeding siblings
				NSUInteger i = 0, j = 0;
				NSUInteger x = 1;
				CFMutableArrayRef siblings = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
				NSUInteger sibContentLength;
				NSXMLNode *sib;
				
				while ((sib = [el nextSibling]) != nil) {
					//self.debug(sib.textContent())
					sibContentLength = [self textLength:sib];
					if (sibContentLength) {
						i += 1;
						CFArrayAppendValue(siblings, (void *)sibContentLength);
						if (i == x)  break;
					}
				}
				
				while ((sib = [el previousSibling]) != nil) {
					//self.debug(sib.textContent())
					sibContentLength = [self textLength:sib];
					if (sibContentLength) {
						j += 1;
						CFArrayAppendValue(siblings, (void *)sibContentLength);
						if (j == x)  break;
					}
				}
				
				//self.debug(str(siblings))
				
				if ((CFArrayGetCount(siblings) > 0)
					&& (sumCFArrayOfNSUInteger(siblings) > 1000)) {
					
					toRemove = NO;
					[self debug:[NSString stringWithFormat:@"Allowing %@", el]];
					
					BOOL yesBool = YES;
					for (NSXMLElement *desnode in [self tagsIn:el withNames:@"table", @"ul", @"div", nil]) {
						CFDictionarySetValue(allowed, [HashableElement elementForNode:desnode], (void *)yesBool);
					}
				}
				
				CFRelease(siblings);

				if (toRemove) {
					[self debug:[NSString stringWithFormat:@"Cleaned %6.3f %@ with weight %f cause it has %@.", 								 contentScore, el, weight, reason]];
					//print tounicode(el)
					//self.debug("pname %s pweight %.3f" %(pname, pweight))
					[el detach];
				}
			}
			
			CFRelease(counts);
			
		}
	}

	/*
	for el in ([node] + [n for n in node.iter()]):
		if not (self.options['attributes']):
			//el.attrib = {} //FIXME:Checkout the effects of disabling this
			pass
	 */
		
	CFRelease(allowed);
	
	return node;
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
		
		NSDictionary *bestCandidate = [self selectBestCandidate:candidates];

		NSXMLDocument *article = nil;
		
		if (bestCandidate != nil) {
					article = [self getArticleForCandidates:candidates 
										   andBestCandidate:bestCandidate];
		}
		else {
			if (ruthless) {
				NSLog(@"Ruthless removal did not work. ");
				ruthless = NO;
				[self debug:@"Ended up stripping too much - going for a safer _parse"];
				// try again
				continue;
			}
			else {
				NSLog(@"Ruthless and lenient parsing did not work. Returning raw html");
				if ([self.html kind] == NSXMLElementKind) {
					article = [[(NSXMLElement *)self.html elementsForName:@"body"] objectAtIndex:0];
				}
				if (article == nil) {
					article = self.html;
				}
				
			}
		}
		
		NSXMLDocument *cleanedArticle = [self sanitizeArticle:article forCandidates:candidates];
		//[self cleanAttributes:]
		NSUInteger cleanedArticleLength = (cleanedArticle == nil) ? 0 : [[cleanedArticle XMLString] length];
		NSNumber *retryLengthNum = [self.options objectForKey:@"retryLength"];
		NSUInteger retryLength = (retryLengthNum != nil) ? [retryLengthNum unsignedIntegerValue] : RETRY_LENGTH;
		BOOL ofAcceptableLength = cleanedArticleLength >= retryLength;
		if (ruthless && !ofAcceptableLength) {
			ruthless = NO;
			continue;
		}
		else {
			return cleanedArticle;
		}
		
	}

}

@end


@implementation HashableElement

@synthesize node = _node;

+ (id)elementForNode:(NSXMLNode *)aNode;
{
	return [[[self alloc] initWithNode:aNode] autorelease];
}

- (id)initWithNode:(NSXMLNode *)aNode;
{
	self = [super init];
	if (self) {
		self.node = aNode;
	}
	return self;
}

- (void)dealloc
{
    self.node = nil;
	
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] allocWithZone:zone]
					 initWithNode:self.node];
	
	return newElement;
}


- (NSString *)description
{
	return [self.node description];
}

- (BOOL)isEqual:(id)obj
{
	if (obj == nil)  return NO;
	if (![obj isKindOfClass:[HashableElement class]])  return NO;
	
	HashableElement *p = (HashableElement *)obj;
	NSXMLNode *pNode = p.node;
	NSXMLNode *selfNode = self.node;
	return [pNode isEqualTo:selfNode] && [pNode.children isEqual:selfNode.children];
}

- (BOOL)isEqualToElement:(HashableElement *)p
{
	if (p == nil)  return NO;
	
	NSXMLNode *pNode = p.node;
	NSXMLNode *selfNode = self.node;
	return [pNode isEqualTo:selfNode] && [pNode.children isEqual:selfNode.children];
}

- (NSUInteger)hash
{
	NSXMLNode *selfNode = self.node;
	return ([selfNode hash] ^ [selfNode.children hash]);
}

@end
