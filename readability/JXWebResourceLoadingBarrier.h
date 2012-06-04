//
//  JXWebResourceLoadingBarrier.h
//  readability
//
//  Created by Jan on 04.06.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface JXWebResourceLoadingBarrier : NSObject {
	BOOL localResourceLoadingOnly;
}

@property (nonatomic) BOOL localResourceLoadingOnly;

@end
