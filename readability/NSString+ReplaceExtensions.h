//
//  NSString+ReplaceExtensions.h
//  readability
//
//  Created by Georg Fritzsche on 17.09.10.
//  http://stackoverflow.com/questions/3733980/replace-multiple-groups-of-characters-in-an-nsstring
//

#import <Foundation/Foundation.h>

@interface NSString (ReplaceExtensions)
- (NSString *)stringByReplacingStringsFromDictionary:(NSDictionary *)dict;
@end
