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

#import <Foundation/Foundation.h>

// Class for cleaning up an NSXMLDocument to improve readability.

@interface JXReadabilityDocument : NSObject
{
	NSString *				input;
	NSXMLDocument *			html;
	
	NSMutableDictionary *	options;

	NSCharacterSet *		whitespaceAndNewlineCharacterSet;
	
	NSRegularExpression *	unlikelyCandidatesRe;
	NSRegularExpression *	okMaybeItsACandidateRe;
	NSRegularExpression *	positiveRe;
	NSRegularExpression *	negativeRe;
	NSRegularExpression *	divToPElementsRe;

	NSRegularExpression *	newlinePlusSurroundingwhitespaceRe;
	NSRegularExpression *	tabRunRe;
	NSRegularExpression *	sentenceEndRe;
	
	NSSet *					divToPElementsTagNames;
}

@property (nonatomic, copy) NSString *input;
@property (nonatomic, strong) NSXMLDocument *html;

@property (nonatomic, strong) NSMutableDictionary *options;
/*
Possible keys (in flux):
 - attributes: (currently disabled)
 - debug (NSNumber): output debug messages
 - minTextLength: 
 - retryLength: 
 - url: will allow adjusting links to be absolute
 */

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *shortTitle;

- (id)initWithXMLDocument:(NSXMLDocument *)aDoc copyDocument:(BOOL)doCopy;
- (id)initWithXMLDocument:(NSXMLDocument *)aDoc; // Same as above with doCopy == NO

// Generate and return the summary of the HTML document
- (NSXMLDocument *)summaryXMLDocument;

@end
