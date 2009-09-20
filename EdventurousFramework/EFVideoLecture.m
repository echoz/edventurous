//
//  EFVideoLecture.m
//  edventurous
//
//  Created by Jeremy Foo on 9/18/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import "EFVideoLecture.h"

@implementation EFVideoLecture

@synthesize url, currentURL, videoURL, videoFileURL, movie, processed, delegate, webvUserAgent, terminatingCondition;
@synthesize title, desc, author, email, creationDate;

#pragma mark -
#pragma mark Initialisation

-(id)initWithURL:(NSString *)theUrl webViewUserAgent:(NSString *) useragent terminatingCondition:(NSString *) tc {
	processed = NO;
	url = theUrl;
	terminatingCondition = tc;
	webvUserAgent = useragent;
	webv = [[WebView alloc] initWithFrame:NSRectFromCGRect(CGRectZero)];
	[webv setFrameLoadDelegate:self];
	[webv setCustomUserAgent:webvUserAgent];
	
	return self;
}

#pragma mark processes

-(void) process {
	if (!processed) {
		[webv setMainFrameURL:url];
		
		EFGrabURL *metadata = [[EFGrabURL alloc] initWithURLString:url];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotMetadata:) name:EFGrabURLFinishedNotification object:metadata];
	}
}

-(void) refresh {
	processed = NO;
	[self process];
}

#pragma mark metadata

-(void)gotMetadata:(NSNotification *)notification {
	static NSString * parseRegex = @"<tr><td width=\"[0-9]+%\" class=\"[a-zA-Z0-9]+\"><b>Title</b>:</td><td class=\"[a-zA-Z0-9]+\">(.*)</td><td valign=\"[a-zA-Z]+\" align=\"[a-zA-Z]+\" width=\"[0-9]+\" rowspan=\"[0-9]+\"><img src=\".*\" width=\"[0-9]+\" height=\"[0-9]+\" border=\"[0-9]+\"></td></tr><tr><td class=\"[0-9a-zA-Z]+\"><b>Description</b>:</td><td class=\"[0-9a-zA-Z]+\">(.*)</td></tr><tr><td class=\"[0-9a-zA-Z]+\"><b>Author</b>:</td><td class=\"[0-9a-zA-Z]+\">(.*)</td></tr><tr><td class=\"[0-9a-zA-Z]+\"><b>Email</b>:</td><td class=\"[0-9a-zA-Z]+\">(.*)</td></tr><tr><td class=\"[0-9a-zA-Z]+\"><b>Mp3</b>:</td><td class=\"[0-9a-zA-Z]+\">(Yes|No)</td></tr><tr><td class=\"[0-9a-zA-Z]+\"><b>Mp4</b>:</td><td class=\"[0-9a-zA-Z]+\">(Yes|No)</td></tr><tr><td class=\"[0-9a-zA-Z]+\"><b>Creation Date</b>:</td><td class=\"[0-9a-zA-Z]+\">([0-9/]+)</td></tr>";
	if ([notification name] == EFGrabURLFinishedNotification) {
		NSString * doc = [notification object];
		doc = [[doc stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfRegex:@"\t" withString:@""];
		NSArray * captures = [doc componentsMatchedByRegex:parseRegex];
		
		if ([captures count] > 0) {
			title = [captures objectAtIndex:0];
			desc = [captures objectAtIndex:1];
			author = [captures objectAtIndex:2];
			email = [captures objectAtIndex:3];
			NSArray * dateComponents = [[captures objectAtIndex:6] componentsMatchedByRegex:@"([0-9]+)/([0-9]+)/([0-9]+)"];
			
			NSDateComponents *components = [[NSDateComponents alloc] init];
			[components setDay:[[dateComponents objectAtIndex:0] intValue]];
			[components setMonth:[[dateComponents objectAtIndex:1] intValue]];
			[components setYear:[[dateComponents objectAtIndex:2] intValue]];
			creationDate = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] dateFromComponents:components];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserEndLoadMetadata object:self];			
		}
	}
}

#pragma mark webview delegate methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	if (!processed) {
		[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserDidLoadNotification object:self];
		currentURL = [sender mainFrameURL];
		NSLog(@"Starting load of %@",[sender mainFrameURL]);			
	}
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	NSString *doc = [[NSString alloc] initWithData:[[frame dataSource] data] encoding:NSASCIIStringEncoding];
	NSRange test = [doc rangeOfString:terminatingCondition];	
	static NSString * videoRegex1 = @"<param name=\"SRC\" value=\"(http://.*)play.asx\">";
	static NSString * videoRegex2 = @"AcuSetBasePath\\(\"(http://.*)\".replace\\(\"https:\",\"http:\"\\)\\);";

	
	if (test.location == NSNotFound) {
		if ([[sender mainFrameURL] rangeOfString:@"defaultmac.asp"].location == NSNotFound) {
			[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserEndLoadNotification object:self];			
		} else {
			NSString * link = [doc stringByMatching:@"var sTargetUrl = \"(.*)\";" capture:1];
			[sender setMainFrameURL:[[sender mainFrameURL] stringByReplacingOccurrencesOfRegex:@"defaultmac.asp" withString:link]];
			[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserDidFindVideoURLNotification object:self];
			
		}
		
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserDidCompleteNotification object:self];
		processed = YES;
		
		videoURL = [doc stringByMatching:videoRegex1 capture:1];
		if (videoURL == nil) {
			videoURL = [doc stringByMatching:videoRegex2 capture:1];
		}
		
		videoURL = [videoURL stringByAppendingFormat:@"play.asx"];
		
		movie = [QTMovie movieWithURL:[NSURL URLWithString:videoURL] error:nil];
	}
	
}

@end
