//
//  SignatureEngine.h
//  edventurous
//
//  Created by Jeremy Foo on 9/11/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SynthesizeSingleton.h"

@interface SignatureEngine : NSObject {
	NSManagedObjectContext * managedContext;
	NSManagedObjectModel * managedModel;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSArray *signatures;
}
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedContext;
@property (nonatomic, retain) NSArray *signatures;

+(SignatureEngine *)sharedSignatureEngine;
-(void)reloadData;

@end
