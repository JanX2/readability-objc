//
//  NSString+JXRemoving.h
//  string-splitter
//
//  Created by Jan on 11.01.12.
//  Copyright 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Removing)

- (NSString *)jx_stringByRemovingPrefix:(NSString *)prefix;
- (NSString *)jx_stringByRemovingSuffix:(NSString *)suffix;
- (NSString *)jx_stringByRemovingSurroundingWhitespace;
- (NSString *)jx_stringByCollapsingAndRemovingSurroundingCharactersInSet:(NSCharacterSet *)collapsibleCharacterSet 
															  intoString:(NSString *)replacementString;

@end
