//
//  EFVideoLecture.h
//  edventurous
//
//  Created by Jeremy Foo on 9/18/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <QTKit/QTKit.h>
#import "RegexKitLite.h"
#import "EFGrabURL.h"

@class EFVideoLecture;

//notification objects
NSString * const EFVideoLectureParserEndLoadMetadata;
NSString * const EFVideoLectureParserDidLoadNotification;
NSString * const EFVideoLectureParserEndLoadNotification;
NSString * const EFVideoLectureParserDidCompleteNotification;
NSString * const EFVideoLectureParserDidFindVideoURLNotification;

@interface EFVideoLecture : NSObject {
	NSString * url;
	NSString * videoURL;
	NSString * videoFileURL;
	QTMovie * movie;
	WebView * webv;
	NSString * webvUserAgent;
	NSString * terminatingCondition;
	NSString * currentURL;
	BOOL processed;
	id delegate;
	
	NSString * title;
	NSString * desc;
	NSString * author;
	NSString * email;
	NSDate * creationDate;
	
	NSMutableData * receivedData;
	EFGrabURL *metadata;
}

@property (readonly) NSString * title;
@property (readonly) NSString * desc;
@property (readonly) NSString * author;
@property (readonly) NSString * email;
@property (readonly) NSDate * creationDate;

@property (nonatomic, retain) NSString * url;
@property (readonly) NSString * currentURL;
@property (nonatomic, retain) NSString * webvUserAgent;
@property (nonatomic, retain) NSString * terminatingCondition;

@property (readonly) NSString * videoURL;
@property (readonly) NSString * videoFileURL;
@property (readonly) QTMovie * movie;
@property (getter=isProcessed) BOOL processed;
@property (nonatomic, assign) id delegate;

-(id)initWithURL:(NSString *)theUrl webViewUserAgent:(NSString *) useragent terminatingCondition:(NSString *) tc;
-(void) process;
-(void) refresh;

-(void)gotMetadata:(id)sender;
@end
