//
//  main.m
//  readability
//
//  Created by Jan on 23.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Webkit/Webkit.h>
#import <WebKit/WebArchive.h>

#import "KBWebArchiver.h"
#import "JXReadabilityDocument.h"

int main(int argc, const char * argv[])
{

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	{
		NSError *error = nil;

		NSUserDefaults *args = [NSUserDefaults standardUserDefaults];	
		
		NSString *urlString = [args stringForKey:@"url"];
		NSString *localOnlyString = [args stringForKey:@"local"];
		NSString *verboseString = [args stringForKey:@"verbose"];
		NSString *output = [args stringForKey:@"output"];
		
		BOOL localOnly = [localOnlyString isEqualToString:@"YES"];
		BOOL verbose = [verboseString isEqualToString:@"YES"];
		
		if (urlString == nil) {
#if 0
			NSArray *arguments = [[NSProcessInfo processInfo] arguments];
			const char *executablePath = [[arguments objectAtIndex:0] 
										  fileSystemRepresentation];
#endif
			fprintf(stderr, "readability 0.1\nUsage: \nreadability -url URL [-verbose YES|NO] -output FILE \n");
			
			[pool drain];
			return EXIT_FAILURE;
		}
		

		WebArchive *webarchive;
		KBWebArchiver *archiver = [[KBWebArchiver alloc] initWithURLString:urlString];
		archiver.localResourceLoadingOnly = localOnly;
		webarchive = [archiver webArchive];
		NSData *data = [webarchive data];
		error = [archiver error];
		[archiver release];
		
		if ( webarchive == nil || data == nil ) {
			fprintf(stderr, "Error: Unable to create webarchive\n");
			if (error != nil)  fprintf(stderr, "%s\n", [[error description] UTF8String]);
			
			[pool drain];
			return EXIT_FAILURE;
		}

		WebResource *resource = [webarchive mainResource];
		
		NSString *textEncodingName = [resource textEncodingName];
		
		NSStringEncoding encoding;
		if (textEncodingName == nil) {
			encoding = NSISOLatin1StringEncoding;
		}
		else {
			CFStringEncoding cfEnc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName);
			if (kCFStringEncodingInvalidId == cfEnc) {
				encoding = NSUTF8StringEncoding;
			}
			else {
				encoding = CFStringConvertEncodingToNSStringEncoding(cfEnc);
			}
		}
		
		NSString *source = [[[NSString alloc] initWithData:[resource data] 
												  encoding:encoding] autorelease];
		
		NSString *result = source;

		
		NSXMLDocumentContentKind contentKind = NSXMLDocumentXHTMLKind;
		
		NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:source 
															  options:NSXMLDocumentTidyHTML 
																error:&error];
		NSXMLDocument *summaryDoc = nil;
		
		if (doc != nil) {
			[doc setDocumentContentKind:contentKind];
			
			JXReadabilityDocument *readabilityDoc = [[JXReadabilityDocument alloc] initWithXMLDocument:doc];
			summaryDoc = [readabilityDoc summaryXMLDocument];
			[readabilityDoc release];
		}

		
		if (result == nil) {
			NSLog(@"\n%@", error);
		}
		
		
		if (output == nil) {
			fprintf(stdout, "%s\n", [result UTF8String]);
		}
		else {
			BOOL OK;
			
			if (doc != nil)	{
				NSData *docData = [doc XMLDataWithOptions:contentKind];
				OK = [docData writeToFile:output  
							 options:NSDataWritingAtomic 
							   error:&error];
			}
			else {
				OK = NO;
			}
			
			if (!OK && verbose) {
				NSLog(@"\n%@", error);
			}
		}
		
		if (doc != nil)	{
			[doc release];
		}
		
	}
	
	[pool drain];
	return EXIT_SUCCESS;
}
