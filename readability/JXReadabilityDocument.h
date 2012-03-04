//
//  JXReadablilityDocument.h
//  readability
//
//  Created by Jan on 25.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>

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
}

@property (nonatomic, copy) NSString *input;
@property (nonatomic, retain) NSXMLDocument *html;

@property (nonatomic, retain) NSMutableDictionary *options;

- (id)initWithXMLDocument:(NSXMLDocument *)aDoc;

- (NSXMLDocument *)summaryXMLDocument;

@end
