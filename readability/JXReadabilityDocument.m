//
//  JXReadablilityDocument.m
//  readability
//
//  Created by Jan on 25.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "JXReadabilityDocument.h"

#define TEXT_LENGTH_THRESHOLD	25
#define RETRY_LENGTH			250

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
	}
	
	return self;
}

- (void)dealloc
{
	self.html = nil;
	self.options = nil;
	
	[super dealloc];
}



- (NSXMLDocument *)summaryXMLDocument;
{
	return nil;
}

@end
