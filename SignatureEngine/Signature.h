//
//  Signature.h
//  edventurous
//
//  Created by Jeremy Foo on 9/11/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "RegexKitLite.h"

@interface Signature : NSManagedObject {

}


// coredata attributes
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *comments;
@property (nonatomic, retain) NSString *regex;
@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) NSNumber *priority;
@end
