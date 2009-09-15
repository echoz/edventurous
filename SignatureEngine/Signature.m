//
//  Signature.m
//  edventurous
//
//  Created by Jeremy Foo on 9/11/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import "Signature.h"


@implementation Signature
@dynamic name, comments, regex, prefix, suffix, priority;

-(BOOL)matchesString:(NSString *)aString {
	return ([aString stringByMatching:self.regex] == nil)?NO:YES;
}

-(NSRange)rangeOfMatchedString:(NSString *)aString {
	return [aString rangeOfRegex:self.regex];
}

@end
