//
//  main.m
//  readability
//
//  Created by Jan on 23.02.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{

	@autoreleasepool {
	    
		NSUserDefaults *args = [NSUserDefaults standardUserDefaults];	
		
		NSString *url = [args stringForKey:@"url"];
		NSString *verboseString = [args stringForKey:@"verbose"];
		NSString *output = [args stringForKey:@"output"];
		
		BOOL verbose = [verboseString isEqualToString:@"YES"];
		
		BOOL isPath;
		
		if (url == nil) {
#if 0
			NSArray *arguments = [[NSProcessInfo processInfo] arguments];
			const char *executablePath = [[arguments objectAtIndex:0] 
										  fileSystemRepresentation];
#endif
			fprintf(stderr, "readability 0.1\nUsage: \nreadability -url URL [-verbose YES|NO] -output FILE \n");
			
			return EXIT_FAILURE;
		}
		
		if ([url hasPrefix:@"http://"]) {
			isPath = NO;
		} else {
			isPath = YES;
		}
		
	    
		NSString *result = @"";
		
		
		if (output == nil) {
			fprintf(stdout, "%s\n", [result UTF8String]);
		}
		else {
			NSError *error = nil;
			BOOL OK = [result writeToFile:result 
							   atomically:YES 
								 encoding:NSUTF8StringEncoding 
									error:&error];
			
			if (!OK && verbose) {
				NSLog(@"\n%@", error);
			}
		}
		
	}
	
	return EXIT_SUCCESS;
}

