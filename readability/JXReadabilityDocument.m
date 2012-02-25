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

- (NSXMLDocument *)summaryXMLDocument;
{
	if (self.html == nil)  return nil;
	
	BOOL ruthless = YES;
	while (1) {
		//[self _html:YES];
		
		NSArray *nodes;
		
		// Delete non-content nodes
		nodes = [self tagsIn:self.html withNames:@"script", @"style", nil];
		for (NSXMLNode *i in nodes) {
			[i detach];
		}
		
		// Add readability CSS ID to body tag
		nodes = [self tagsIn:self.html withNames:@"body", nil];
		for (NSXMLNode *i in nodes) {
			[i addCSSName:@"readabilityBody" toAttributeWithName:@"id"];
		}
	
		return self.html;
	}
}

@end
