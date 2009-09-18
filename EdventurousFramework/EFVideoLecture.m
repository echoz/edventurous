//
//  EFVideoLecture.m
//  edventurous
//
//  Created by Jeremy Foo on 9/18/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import "EFVideoLecture.h"

@implementation EFVideoLecture

@synthesize url, videoURL, videoFileURL, movie, processed, delegate, webvUserAgent, terminatingCondition;
@synthesize title, desc, author, email, creationDate;

#pragma mark notification declarations

NSString * const EFVideoLectureParserStartLoad;
NSString * const EFVideoLectureParserDoneLoad;
NSString * const EFVideoLectureParserComplete;
NSString * const EFVideoLectureParserFoundVideoURL;

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
		
	}
}

-(void) refresh {
	processed = NO;
	[self process];
}

#pragma mark webview delegate methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	if (!processed) {
		[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserStartLoad object:self];
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
			[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserDoneLoad object:self];			
		} else {
			NSString * link = [doc stringByMatching:@"var sTargetUrl = \"(.*)\";" capture:1];
			[sender setMainFrameURL:[[sender mainFrameURL] stringByReplacingOccurrencesOfRegex:@"defaultmac.asp" withString:link]];
			[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserFoundVideoURL object:self];
			
		}
		
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:EFVideoLectureParserComplete object:self];
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
