//
//  JXWebResourceLoadingBarrier.m
//  readability
//
//  Created by Jan on 04.06.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "JXWebResourceLoadingBarrier.h"

@implementation JXWebResourceLoadingBarrier

@synthesize localResourceLoadingOnly;

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
	if (!localResourceLoadingOnly 
		|| (localResourceLoadingOnly && [[[request URL] scheme] isEqualToString:@"file"]))
	{
		return request;
	} else {
		return nil;
	}
}


@end
