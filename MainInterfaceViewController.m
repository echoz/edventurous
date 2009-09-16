//
//  MainInterfaceViewController.m
//  edventurous
//
//  Created by Jeremy Foo on 9/11/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import "MainInterfaceViewController.h"


@implementation MainInterfaceViewController
@synthesize webv, sigEngine;
@synthesize urlInput, urlInputView, window, titleLabel, progressLabel, progressWindow, progressIndicator, movie, originalSize;

#define WEBVIEW_USERAGENT @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; fi-fi) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9"
#define CLASSID_TOHUNTFOR @"classid=\"CLSID:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B\""

- (void)awakeFromNib
{
	webv = [[WebView alloc] initWithFrame:NSRectFromCGRect(CGRectZero)];
	[webv setFrameLoadDelegate:self];
	[webv setCustomUserAgent:WEBVIEW_USERAGENT];
	//	[webv setShouldUpdateWhileOffscreen:NO];
	sigEngine = [SignatureEngine sharedSignatureEngine];
	gotPage = NO;
	originalSize = NSMakeSize(movie.frame.size.width, movie.frame.size.height);
}

-(IBAction)finishedInput:(id)sender {
	if (![[urlInput stringValue] hasPrefix:@"http://"]) {
		[urlInput setStringValue:[@"http://" stringByAppendingString:[urlInput stringValue]]];
	}
	
	[webv setMainFrameURL:[urlInput stringValue]];
	[self closeInput:sender];
	[[NSApplication sharedApplication] beginSheet:progressWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[progressIndicator startAnimation:sender];
}


-(IBAction)closeInput:(id)sender {
	[self doneWithSheet:urlInputView withSender:sender];
}

-(IBAction) resize2x:(id)sender {
	[self resizeMovieByx:2];
}

-(IBAction) resize1point5x:(id)sender {
	[self resizeMovieByx:1.5];
}

-(IBAction) resizeOriginal:(id)sender {
	[self resizeMovieByx:0];
}

-(void)resizeMovieByx:(float)magnitude {
	CGFloat extraHeight = (window.frame.size.height-movie.frame.size.height) + 16.0;	
	
	if (magnitude == 0.0) {
		[window setFrame:NSMakeRect(window.frame.origin.x, window.frame.origin.y, originalSize.width, originalSize.height + extraHeight) display:YES animate:YES];		
	} else {
		[window setFrame:NSMakeRect(window.frame.origin.x, window.frame.origin.y, originalSize.width * magnitude, (originalSize.height*magnitude)+ extraHeight) display:YES animate:YES];
	}
	NSLog(@"Resizing to w:%f, h:%f",window.frame.size.width, window.frame.size.height);	
}

-(void)doneWithSheet:(NSWindow *)sheet withSender:(id)sender {
	[[NSApplication sharedApplication] endSheet:sheet];
	[sheet orderOut:sender];		
}

-(IBAction)cancelProcessing:(id)sender {
	[self doneWithSheet:progressWindow withSender:sender];
	[webv setMainFrameURL:@"file:///tmp"];
	NSLog(@"Cancelled processing of pages");

}

-(IBAction) showURLInputView:(id)sender {

	[[NSApplication sharedApplication] beginSheet:urlInputView modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];

}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	if (!gotPage) {
		[progressLabel setStringValue:[@"Processing " stringByAppendingString:[sender mainFrameURL]]];
		NSLog(@"Starting load of %@",[sender mainFrameURL]);			
	}
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	NSString *doc = [[NSString alloc] initWithData:[[frame dataSource] data] encoding:NSASCIIStringEncoding];
	NSRange test = [doc rangeOfString:CLASSID_TOHUNTFOR];	
	static NSString * videoRegex1 = @"<param name=\"SRC\" value=\"(http://.*)play.asx\">";
	static NSString * videoRegex2 = @"AcuSetBasePath\\(\"(http://.*)\".replace\\(\"https:\",\"http:\"\\)\\);";
//	static NSString * qtpLink = @"http://www.apple.com/quicktime";
//	static NSString * f4mLink = @"http://www.microsoft.com/windows/windowsmedia/player/flip4mac.mspx";
	NSString *videoURL;
	
	NSLog(@"%@",doc);
	
	if (test.location != NSNotFound) {
		gotPage = YES;
		[titleLabel setStringValue:[sender mainFrameURL]];

		videoURL = [doc stringByMatching:videoRegex1 capture:1];
		if (videoURL == nil) {
			videoURL = [doc stringByMatching:videoRegex2 capture:1];
		}
		
		videoURL = [videoURL stringByAppendingFormat:@"play.asx"];
			
		NSLog(@"Video URL is %@", videoURL);
		
		QTMovie *video = [QTMovie movieWithURL:[NSURL URLWithString:videoURL] error:nil];
		NSSize testNaturalSize = [[[video movieAttributes] valueForKey:QTMovieNaturalSizeAttribute] sizeValue];
		NSSize testCurrentSize = [[[video movieAttributes] valueForKey:QTMovieCurrentSizeAttribute] sizeValue];		

		if ((testCurrentSize.height != 0) && (testCurrentSize.width != 0)) {
			originalSize = testCurrentSize;
		}		
		
		if ((testNaturalSize.height != 0) && (testNaturalSize.width != 0)) {
			originalSize = testNaturalSize;
		}

		NSLog(@"natural size is w:%f, h:%f", originalSize.width, originalSize.height);
		
		[movie setMovie:video];
		
		[progressIndicator stopAnimation:sender];
		[self doneWithSheet:progressWindow withSender:sender];

		[self resizeMovieByx:0];
				
	} else {
		NSLog(@"done loading frame for %@", [sender mainFrameURL]);
		if ([[sender mainFrameURL] rangeOfString:@"defaultmac.asp"].location != NSNotFound) {
			NSString * link = [doc stringByMatching:@"var sTargetUrl = \"(.*)\";" capture:1];
			[progressLabel setStringValue:[@"Found Video page. Forwarding to " stringByAppendingString:link]];
			[sender setMainFrameURL:[[sender mainFrameURL] stringByReplacingOccurrencesOfRegex:@"defaultmac.asp" withString:link]];
			NSLog(@"Found video page. Forwarding.");
			
		}
		
		/*
		if ([doc rangeOfString:@"to download and install Flip4Mac plugin. You can double click on the downloaded file to install it when download completed."].location != NSNotFound) {
			NSLog(@"No Flip4Mac components!");
			[self doneWithSheet:progressWindow withSender:sender];
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:@"OK"];
			[alert addButtonWithTitle:@"Download Flip4Mac"];
			[alert addButtonWithTitle:@"Download Qucktime Player"];
			[alert setMessageText:@"Your system is not up to the requirements for viewing video lectures"];
			[alert setInformativeText:@"Please ensure you have Flip4Mac WMV components as well as QuickTime 7.0"];
			[alert setAlertStyle:NSWarningAlertStyle];
			NSInteger result = [alert runModal];
			
			if (result == NSAlertSecondButtonReturn) {
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:f4mLink]];
			} else if (result == NSAlertThirdButtonReturn) {
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:qtpLink]];
			}
		}
		 */
				   
	}
}

@end
