//
//  EFGrabPage.h
//  edventurous
//
//  Created by Jeremy Foo on 9/20/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import <Foundation/Foundation.h>

// notification objects
NSString * const EFGrabURLFinishedNotification;

@interface EFGrabURL : NSObject {
	NSMutableData * receivedData;
}

@property (readonly) NSMutableData * receivedData;
-(id)initWithURLString:(NSString *)theUrl;
@end