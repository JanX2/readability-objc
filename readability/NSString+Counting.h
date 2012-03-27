//
//  NSString+Counting.h
//  readability
//
//  Created by Jan on 05.03.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Counting)

- (NSUInteger)countOccurancesOfString:(NSString *)needle;
- (NSUInteger)countSubstringsWithOptions:(NSStringEnumerationOptions)opts;
- (BOOL)countOfSubstringsWithOptions:(NSStringEnumerationOptions)opts isAtLeast:(NSUInteger)lowerBound;

@end
