/*
 * JXReadablilityDocument
 *
 * Copyright (c) 2012 geheimwerk.de.
 * https://github.com/JanX2/readability-objc
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * ObjC port: jan@geheimwerk.de (Jan Weiß)
 */

#import "JXReadabilityDocument.h"

#import "htmls.h"
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


NSString * const	divToPElementsTagNamesString =	@"a|blockquote|dl|div|img|ol|p|pre|table|ul";


NSSet * stringSetForListStringDelimitedBy(NSString *listString, NSString *delimiter);


@interface HashableElement : NSObject <NSCopying> {
	NSXMLNode *_node;
}

@property (nonatomic, retain) NSXMLNode *node;

+ (id)elementForNode:(NSXMLNode *)aNode;
- (id)initWithNode:(NSXMLNode *)aNode;

@end

NSSet * stringSetForListStringDelimitedBy(NSString *listString, NSString *delimiter) {
	NSArray *strings = [listString componentsSeparatedByString:delimiter];
	
	NSSet *stringSet = [NSSet setWithArray:strings];
	
	return stringSet;
}


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
		
		NSString *delimiter = @"|";
		divToPElementsTagNames = 	[stringSetForListStringDelimitedBy(divToPElementsTagNamesString, delimiter) retain];

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
	
	[divToPElementsTagNames release];
	
	[super dealloc];
}


- (NSString *)title;
{
	return getTitleInDocument(self.html);
}

- (NSString *)shortTitle;
{
	return shortenTitleInDocument(self.html);
}


- (void)debug:(id)a
{
	if ([(NSNumber *)(self.options)[@"debug"] boolValue]) {
		NSLog(@"%@", a);
	}
}

- (void)removeUnlikelyCandidates
{
	NSXMLNode *elem = self.html;
	
	do {
		if ([elem kind] == NSXMLElementKind) {
			NSString *classes = [elem cssNamesForAttributeWithName:@"class"];
			NSString *ids = [elem cssNamesForAttributeWithName:@"id"];
			
			if (classes == nil && ids == nil)  continue;

			NSString *s = [NSString stringWithFormat:@"%@ %@", 
						   (classes == nil ? @"" : classes), 
						   (ids == nil ? @"" : ids)];
			NSRange sRange = NSMakeRange(0, [s length]);
			
			if (sRange.length < 2)  continue;
			
			//[self debug:s];
			
			if (([unlikelyCandidatesRe rangeOfFirstMatchInString:s options:0 range:sRange].location != NSNotFound) 
				&& ([okMaybeItsACandidateRe rangeOfFirstMatchInString:s options:0 range:sRange].location == NSNotFound)
				&& ![elem.name isEqualToString:@"html"]
				&& ![elem.name isEqualToString:@"body"]) {
				//[self debug:[NSString stringWithFormat:@"Removing unlikely candidate - %@", [elem readabilityDescription]]];
				[elem detach];
			}
		}
		
	} while ((elem = [elem nextNode]) != nil);
}

- (void)transformMisusedDivsIntoParagraphs
{
	NSArray *nodes;
	
	nodes = [self.html tagsWithNames:@"div", nil];
	for (NSXMLNode *elem in nodes) {
		// Transform <div>s that do not contain other block elements into <p>s
		NSXMLNode *elemNextSibling = [elem nextSibling];
		NSXMLNode *descendant = elem;
		BOOL blockElementFound = NO;
		
		while ((descendant = [descendant nextNode]) != elemNextSibling) {
			if ([divToPElementsTagNames containsObject:descendant.name]) {
				blockElementFound = YES;
				break;
			}
		}
		
		if (blockElementFound == NO) {
			//[self debug:[NSString stringWithFormat:@"Altering %@ to p", [elem readabilityDescription]]];
			[elem setName:@"p"];
			//NSLog(@"Fixed element %@", [elem readabilityDescription]);
		}
	}
	
	NSXMLElement *p;
	NSString *s;
	
	nodes = [self.html tagsWithNames:@"div", nil];
	for (NSXMLElement *elem in nodes) { // div tags always are elements
		
		NSXMLNode *firstTextNode = [elem lxmlTextNode];
		s = [firstTextNode stringValue];
		if ((s != nil)
			&& ([s length] != 0) 
			&& ([[s stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] length] != 0)) { // using -ws_isBlankString would be faster
			
			p = [NSXMLNode elementWithName:@"p" 
							   stringValue:s];
			
			[firstTextNode detach];
			[elem insertChild:p atIndex:0];
			//NSLog(@"Appended %@ to %@", p, [elem readabilityDescription]);
		}
		
		[[elem children] enumerateObjectsWithOptions:NSEnumerationReverse 
										  usingBlock:^(id obj, NSUInteger pos, BOOL *stop) {
											  NSXMLNode *child = obj;
											  NSXMLElement *paragraph;
										  
											  NSXMLNode *tailNode = [child lxmlTailNode];
											  
											  NSString *childTailString = ((tailNode == nil) ? @"" : [tailNode stringValue]);
											  
											  if (([childTailString length] != 0) 
												  && ([[childTailString stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] length] != 0)) { // using -ws_isBlankString would be faster
												  
												  paragraph = [NSXMLNode elementWithName:@"p" 
																			 stringValue:childTailString];
												  
												  [tailNode detach]; // We could get [tailNode index] and insert there after detaching
												  [elem insertChild:paragraph atIndex:(pos + 1)];
												  //NSLog(@"Appended %@ to %@", p, [elem readabilityDescription]);
											  }
											  
											  if ([[child name] isEqualToString:@"br"]) {
												  [child detach];
												  //NSLog(@"Dropped <br> at %@", [elem readabilityDescription]);
											  }
										  }];
		
	}	
}

- (NSString *)clean:(NSString *)_text
{
	NSUInteger textLength = [_text length];
	if (textLength == 0)  return _text;
	
	NSMutableString *text = [_text mutableCopy];
	
	[newlinePlusSurroundingwhitespaceRe replaceMatchesInString:text 
													   options:0 
														 range:NSMakeRange(0, textLength) 
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
	float weight = 0;
	NSString *s;
	
	if ((s = [e cssNamesForAttributeWithName:@"class"]) != nil) {
		NSRange sRange = NSMakeRange(0, [s length]);
		
		if ([negativeRe rangeOfFirstMatchInString:s options:0 range:sRange].location != NSNotFound)  weight -= 25;
		
		if ([positiveRe rangeOfFirstMatchInString:s options:0 range:sRange].location != NSNotFound)  weight += 25;
	}
	
	if ((s = [e cssNamesForAttributeWithName:@"id"]) != nil) {
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
			@(contentScore), @"contentScore", 
			elem, @"elem", 
			nil];
}

- (NSXMLDocument *)getArticleForCandidates:(NSDictionary *)candidates 
						  andBestCandidate:(NSDictionary *)bestCandidate
							   HTMLPartial:(BOOL)HTMLPartial
{
	// Now that we have the top candidate, look through its siblings for content that might also be related
	// Things like preambles, content split by ads that we removed, etc.

	float siblingScoreThreshold = MAX(10.0, ([bestCandidate[@"contentScore"] floatValue] * 0.2));
	
	// Create a new HTML document with a html->body->div
	NSXMLDocument *output = [[[NSXMLDocument alloc] initWithXMLString:@"<html><head><title /></head><body><div id='readibility-root' /></body></html>"
																options:NSXMLDocumentTidyHTML 
																  error:NULL] autorelease];
	[output setDocumentContentKind:NSXMLDocumentXHTMLKind];
	NSXMLElement *htmlDiv = [output nodesForXPath:@"/html/body/div" 
											  error:NULL][0];
#if 0
	// Disabled until we can figure out a good way to return an NSXMLDocument OR an NSXMLElement
	if (HTMLPartial) {
		output = htmlDiv;
	}
#endif
	NSXMLNode *bestElem = bestCandidate[@"elem"];
	
	BOOL append;
	NSDictionary *siblingScoreDict;
	HashableElement *siblingKey;
	for (NSXMLNode *sibling in [[bestElem parent] children]) {
		//if isinstance(sibling, NavigableString): continue
		// in lxml there no concept of simple text 
		append = NO; 
		
		if (sibling == bestElem)  append = YES;
		
		if (append == NO) {
			siblingKey = [HashableElement elementForNode:sibling];
			siblingScoreDict = candidates[siblingKey];
			if ((siblingScoreDict != nil) 
				&& ([siblingScoreDict[@"contentScore"] floatValue] >= siblingScoreThreshold)) {
				append = YES;
			}
		}
		
		if ((append == NO)
			&& [sibling.name isEqualToString:@"p"]
			&& ([sibling kind] == NSXMLElementKind)) {
			
			float linkDensity = [self getLinkDensity:(NSXMLElement *)sibling];
			NSString *nodeContent = [sibling lxmlText];
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
		
		if (append)  [htmlDiv addChild:[[sibling copy] autorelease]];
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
								 @[contentScoreDescendingDescriptor]];
	
#if 0
	NSXMLElement *elem;
	NSArray *topFive = ([sortedCandidates count] >= 5) ? [sortedCandidates subarrayWithRange:NSMakeRange(0, 5)] : sortedCandidates;
	for (NSDictionary *candidate in topFive) {
		elem = [candidate objectForKey:@"elem"];
		[self debug:[NSString stringWithFormat:@"Top 5 : %6.3f %@", [candidate objectForKey:@"contentScore"], [elem readabilityDescription]]];
	}
#endif
	
	NSDictionary *bestCandidate = sortedCandidates[0];
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
	NSNumber *minLength = (self.options)[@"minTextLength"];	
	NSUInteger minLen = (minLength != nil) ? [minLength unsignedIntegerValue] : TEXT_LENGTH_THRESHOLD;
	
	NSMutableDictionary *candidates = [NSMutableDictionary dictionary];
	
#if 0
	for (NSXMLNode *node in [self.html tagsWithNames:@"div", nil]) {
		[self debug:[node readabilityDescription]];
	}
#endif
	
	NSXMLElement *parentNode, *grandParentNode; // parents have to be elements
	NSString *elemTextContent, *innerText;
	NSUInteger innerTextLen;

	NSMutableArray *ordered = [NSMutableArray array];
	HashableElement *hashableParent, *hashableGrandParent;
	for (NSXMLElement *elem in [self.html tagsWithNames:@"p", @"pre", @"td", nil]) {
		parentNode = (NSXMLElement *)[elem parent];
		if (parentNode == nil)  continue;
		grandParentNode = (NSXMLElement *)[parentNode parent];
		
		elemTextContent = [elem stringValue];
		innerText = (elemTextContent != nil) ? [self clean:elemTextContent] : @"";
		innerTextLen = [innerText length];
		
		// If this paragraph is less than 25 characters, don't even count it.
		if (innerTextLen < minLen)  continue;
		
		hashableParent = [HashableElement elementForNode:parentNode];
		if (candidates[hashableParent] == nil) { 
			candidates[hashableParent] = [self scoreNode:parentNode];
			[ordered addObject:parentNode];
		}
		
		if (grandParentNode != nil) {
			hashableGrandParent = [HashableElement elementForNode:grandParentNode];
			if (candidates[hashableGrandParent] == nil) {
				candidates[hashableGrandParent] = [self scoreNode:grandParentNode];
				[ordered addObject:grandParentNode];
			}
		}

		float contentScore = 1.0;
		contentScore += [innerText countOccurancesOfString:@","] + 1;
		contentScore += MIN((innerTextLen / 100), 3);
		//if elem not in candidates:
		//	candidates[elem] = self.scoreNode(elem)
				
		//WTF? candidates[elem]['contentScore'] += contentScore
		float tempScore;
		NSMutableDictionary *scoreDict;
		scoreDict = candidates[hashableParent];
		tempScore = [scoreDict[@"contentScore"] floatValue] + contentScore;
		scoreDict[@"contentScore"] = @(tempScore);
		if (grandParentNode != nil) {
			scoreDict = candidates[hashableGrandParent];
			tempScore = [scoreDict[@"contentScore"] floatValue] + contentScore / 2.0;
			scoreDict[@"contentScore"] = @(tempScore);
		}
	}
	
	// Scale the final candidates score based on link density. Good content should have a
	// relatively small link density (5% or less) and be mostly unaffected by this operation.
	NSMutableDictionary *candidate;
	float ld;
	float score;
	
	for (NSXMLElement *elem in ordered) {
		HashableElement *hashableElem = [HashableElement elementForNode:elem];
		candidate = candidates[hashableElem];
		ld = [self getLinkDensity:elem];
		score = [candidate[@"contentScore"] floatValue];
		//[self debug:[NSString stringWithFormat:@"Candid: %6.3f %s link density %.3f -> %6.3f", score, [elem readabilityDescription], ld, score*(1-ld)]];
		score *= (1 - ld);
		candidate[@"contentScore"] = @(score);
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
#ifndef DEBUG_SANITIZE
#	define DEBUG_SANITIZE	0
#endif
	
	NSNumber *minTextLengthNum = (self.options)[@"minTextLength"];
	NSUInteger minLen = (minTextLengthNum != nil) ? [minTextLengthNum unsignedIntegerValue] : TEXT_LENGTH_THRESHOLD;
	for (NSXMLElement *header in [node tagsWithNames:@"h1", @"h2", @"h3", @"h4", @"h5", @"h6", nil]) {
		if ([self classWeight:header] < 0 || [self getLinkDensity:header] > 0.33) { 
			[header detach];
		}
	}

	for (NSXMLElement *elem in [node tagsWithNames:@"form", @"iframe", @"textarea", nil]) {
		[elem detach];
	}
	
	CFMutableDictionaryRef allowed = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL); // keys: HashableElement, values:raw BOOL
	
	NSDictionary *elDict;
	HashableElement *hashableEl;
	float weight;
	NSString *tag;
	float contentScore;
	CFIndex kindCount;
	NSArray *tagKinds = @[@"p", @"img", @"li", @"a", @"embed", @"input"];
	NSUInteger contentLength;
	float linkDensity;
	NSXMLNode *parentNode;
	
	BOOL toRemove;
#if DEBUG_SANITIZE
	NSString *reason;
#endif

	// Conditionally clean <table>s, <ul>s, and <div>s
	for (NSXMLElement *el in [node tagsWithNames:@"table", @"ul", @"div", nil]) {
		hashableEl = [HashableElement elementForNode:el];
		
		if (CFDictionaryContainsValue(allowed, hashableEl))  continue;
		
		weight = [self classWeight:el];
		
		elDict = candidates[hashableEl];
		if (elDict != nil) {
			contentScore = [elDict[@"contentScore"] floatValue];
			//print '!',el, '-> %6.3f' % contentScore
		}
		else {
			contentScore = 0;
		}
		
		tag = el.name;
		
		if ((weight + contentScore) < 0.0) {
			//[self debug:[NSString stringWithFormat:@"Cleaned %@ with score %6.3f and weight %-3s", [el readabilityDescription], contentScore, weight]];
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
				
#if DEBUG_SANITIZE
				NSDictionary *parentNodeDict = [candidates objectForKey:[HashableElement elementForNode:parentNode]];
				if (parentNodeDict != nil) {
					contentScore = [[parentNodeDict objectForKey:@"contentScore"] floatValue];
				}
				else {
					contentScore = 0.0;
				}
#endif
				
				//if parentNode is not None:
				//	pweight = self.classWeight(parentNode) + contentScore
				//	pname = describe(parentNode)
				//else:
				//	pweight = 0
				//	pname = "no parent"
				
				toRemove = NO;
#if DEBUG_SANITIZE
				reason = @"";
#endif
				
#define countsFor(A)  (CFIndex)(CFDictionaryGetValue(counts, (A)))
				
				//if el.tag == 'div' and counts["img"] >= 1:
				//	continue
				if (countsFor(@"p") 
					&& (countsFor(@"img") > countsFor(@"p"))) {
#if DEBUG_SANITIZE
					reason = [NSString stringWithFormat:@"too many images (%ld)", (long)countsFor(@"img")];
#endif
					toRemove = YES;
				}
				else if ((countsFor(@"li") > countsFor(@"p")) 
						 && ![tag isEqualToString:@"ul"] 
						 && ![tag isEqualToString:@"ol"]) {
#if DEBUG_SANITIZE
					reason = @"more <li>s than <p>s";
#endif
					toRemove = YES;
				}
				else if (countsFor(@"input") > (countsFor(@"p") / 3)) {
#if DEBUG_SANITIZE
					reason = @"less than 3x <p>s than <input>s";
#endif
					toRemove = YES;
				}
				else if ((contentLength < minLen) 
						 && ((countsFor(@"img") == 0) 
							 || (countsFor(@"img") > 2))) {
#if DEBUG_SANITIZE
					reason = [NSString stringWithFormat:@"too short content length %lu without a single image", (unsigned long)contentLength];
#endif
					toRemove = YES;
				}
				else if (weight < 25 && linkDensity > 0.2) {
#if DEBUG_SANITIZE
					reason = [NSString stringWithFormat:@"too many links %.3f for its weight %.0f", linkDensity, weight];
#endif
					toRemove = YES;
				}
				else if (weight >= 25 && linkDensity > 0.5) {
#if DEBUG_SANITIZE
					reason = [NSString stringWithFormat:@"too many links %.3f for its weight %.0f", linkDensity, weight];
#endif
					toRemove = YES;
				}
				else if (((countsFor(@"embed") == 1) && (contentLength < 75)) || (countsFor(@"embed") > 1)) {
#if DEBUG_SANITIZE
					reason = @"<embed>s with too short content length, or too many <embed>s";
#endif
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
				
				// Find x non-empty preceding and succeeding siblings
				NSUInteger i = 0, j = 0;
				NSUInteger x = 1;
				CFMutableArrayRef siblings = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
				NSUInteger sibContentLength;
				NSXMLNode *sib;
				
				sib = el;
				while ((sib = [sib nextSibling]) != nil) {
					//self.debug(sib.textContent())
					sibContentLength = [self textLength:sib];
					if (sibContentLength) {
						i += 1;
						CFArrayAppendValue(siblings, (void *)sibContentLength);
						if (i == x)  break;
					}
				}
				
				sib = el;
				while ((sib = [sib previousSibling]) != nil) {
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
					//[self debug:[NSString stringWithFormat:@"Allowing %@", [el readabilityDescription]]];
					
					BOOL yesBool = YES;
					for (NSXMLElement *desnode in [el tagsWithNames:@"table", @"ul", @"div", nil]) {
						CFDictionarySetValue(allowed, [HashableElement elementForNode:desnode], (void *)(intptr_t)yesBool);
					}
				}
				
				CFRelease(siblings);
				
				if (toRemove) {
#if DEBUG_SANITIZE
					[self debug:[NSString stringWithFormat:@"Cleaned %6.3f %@ with weight %f cause it has %@.", 								 contentScore, [el readabilityDescription], weight, reason]];
#endif
					//print tounicode(el)
					//self.debug("pname %s pweight %.3f" %(pname, pweight))
					[el detach];
				}
			}
			
			CFRelease(counts);
			
		}
	}

	/*
	// This doesn’t appear to do anything!
	for el in ([node] + [n for n in node.iter()]):
		if not (self.options['attributes']):
			//el.attrib = {} //FIXME:Checkout the effects of disabling this
			pass
	 */
		
	CFRelease(allowed);
	
	return node;
}

// HTMLPartial == YES is supposed to request the return of only the div of the document (not wrapped in <html> and <body> tags).
// Currently unsupported. Implemented here to keep parity with python/lxml-readability.
- (NSXMLDocument *)summaryXMLDocument:(BOOL)HTMLPartial;
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
		nodes = [self.html tagsWithNames:@"noscript", @"script", @"style", nil];
		for (NSXMLNode *i in nodes) {
			[i detach];
		}
		
		// Add readability CSS ID to body tag
		nodes = [self.html tagsWithNames:@"body", nil];
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
								   andBestCandidate:bestCandidate
										HTMLPartial:HTMLPartial];
			
			if (HTMLPartial == NO) {
				NSXMLElement *titleNode = [article nodesForXPath:@"/html/head/title" 
															error:NULL][0];
				[titleNode setStringValue:[self title]];
			}
		}
		else {
			if (ruthless) {
				[self debug:@"Ruthless removal did not work. "];
				ruthless = NO;
				//[self debug:@"Ended up stripping too much - going for a safer _parse"];
				// Loop through and try again.
				continue;
			}
			else {
				[self debug:@"Ruthless and lenient parsing did not work. Returning raw html"];
				if ([self.html kind] == NSXMLElementKind) {
					article = [(NSXMLElement *)self.html elementsForName:@"body"][0];
				}
				if (article == nil) {
					article = self.html;
				}
				
			}
		}
		
		NSXMLDocument *cleanedArticle = [self sanitizeArticle:article forCandidates:candidates];
		//[self cleanAttributes:]
		NSUInteger cleanedArticleLength = (cleanedArticle == nil) ? 0 : [[cleanedArticle XMLString] length];
		NSNumber *retryLengthNum = (self.options)[@"retryLength"];
		NSUInteger retryLength = (retryLengthNum != nil) ? [retryLengthNum unsignedIntegerValue] : RETRY_LENGTH;
		BOOL ofAcceptableLength = cleanedArticleLength >= retryLength;
		if (ruthless && !ofAcceptableLength) {
			ruthless = NO;
			// Loop through and try again.
			continue;
		}
		else {
			return cleanedArticle;
		}
		
	}

}

- (NSXMLDocument *)summaryXMLDocument;
{
	return [self summaryXMLDocument:NO];
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
