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

NSString * const EFVideoLectureParserEndLoadMetadata = @"EFVideoLectureParserEndLoadMetadata";
NSString * const EFVideoLectureParserDidLoadNotification = @"EFVideoLectureParserDidLoadNotification";
NSString * const EFVideoLectureParserEndLoadNotification = @"EFVideoLectureParserEndLoadNotification";
NSString * const EFVideoLectureParserDidCompleteNotification = @"EFVideoLectureParserDidCompleteNotification";
NSString * const EFVideoLectureParserDidFindVideoURLNotification = @"EFVideoLectureParserDidFindVideoURLNotification";

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
		
		metadata = [[EFGrabURL alloc] initWithURLString:url];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotMetadata:) name:EFGrabURLFinishedNotification object:metadata];
	}
}

-(void) refresh {
	processed = NO;
	[self process];
}

#pragma mark metadata

-(void)gotMetadata:(NSNotification *)notification {
	static NSString * parseTitle = @"<tr><td width=\"[0-9]+%\" class=\"[a-zA-Z0-9]+\"><b>Title</b>:</td><td class=\"[a-zA-Z0-9]+\">(.*)</td><td valign=\"[a-zA-Z]+\" align=\"[a-zA-Z]+\" width=\"[0-9]+\" rowspan=\"[0-9]+\"><img src=\".*\" width=\"[0-9]+\" height=\"[0-9]+\" border=\"[0-9]+\"></td></tr>";
	static NSString * parseDesc = @"<tr><td class=\"[0-9a-zA-Z]+\"><b>Description</b>:</td><td class=\"[0-9a-zA-Z]+\">(.*)</td></tr>";
	static NSString * parseAuthor = @"<tr><td class=\"[0-9a-zA-Z]+\"><b>Author</b>:</td><td class=\"[0-9a-zA-Z]+\">(.*)</td></tr>";
	static NSString * parseEmail = @"<tr><td class=\"[0-9a-zA-Z]+\"><b>Email</b>:</td><td class=\"[0-9a-zA-Z]+\">(.*)</td></tr>";
	static NSString * parseCreationDate = @"<tr><td class=\"[0-9a-zA-Z]+\"><b>Creation Date</b>:</td><td class=\"[0-9a-zA-Z]+\">([0-9/]+)</td></tr>";
	static NSString * parseDate = @"([0-9]+)/([0-9]+)/([0-9]+)";
	if ([notification name] == EFGrabURLFinishedNotification) {
		
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		
		NSMutableString * doc = [[NSMutableString alloc] initWithData:[[notification object] receivedData] encoding:NSASCIIStringEncoding];
		
		[doc replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [doc length])];
		[doc replaceOccurrencesOfString:@"\t" withString:@"" options:0 range:NSMakeRange(0, [doc length])];
		
		title = [doc stringByMatching:parseTitle capture:1];
		desc = [doc stringByMatching:parseDesc capture:1];
		author = [doc stringByMatching:parseAuthor capture:1];
		email = [doc stringByMatching:parseEmail capture:1];
		
		NSString * test = [doc stringByMatching:parseCreationDate capture:1];
		
		if ([test length] > 0) {
			NSDateComponents *components = [[NSDateComponents alloc] init];
			[components setDay:[[test stringByMatching:parseDate capture:1] intValue]];
			[components setMonth:[[test stringByMatching:parseDate capture:1] intValue]];
			[components setYear:[[test stringByMatching:parseDate capture:1] intValue]];
			creationDate = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] dateFromComponents:components];
		}
				
		[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserEndLoadMetadata object:self];			
	
	}
}

#pragma mark webview delegate methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	if (!processed) {
		currentURL = [sender mainFrameURL];
		NSLog(@"Starting load of %@",[sender mainFrameURL]);			
		[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserDidLoadNotification object:self];
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
		processed = YES;
		
		videoURL = [doc stringByMatching:videoRegex1 capture:1];
		if (videoURL == nil) {
			videoURL = [doc stringByMatching:videoRegex2 capture:1];
		}
		
		videoURL = [videoURL stringByAppendingFormat:@"play.asx"];
		
		movie = [QTMovie movieWithURL:[NSURL URLWithString:videoURL] error:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserDidCompleteNotification object:self];

	}
	
}

@end
