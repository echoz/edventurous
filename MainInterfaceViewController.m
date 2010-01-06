//
//  MainInterfaceViewController.m
//  edventurous
//
//  Created by Jeremy Foo on 9/11/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import "MainInterfaceViewController.h"


@implementation MainInterfaceViewController
@synthesize videolecture, downloadButton;
@synthesize urlInput, urlInputView, window, titleLabel, progressLabel, progressWindow, progressIndicator, movie, originalSize;

#define WEBVIEW_USERAGENT @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; fi-fi) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9"
#define CLASSID_TOHUNTFOR @"classid=\"CLSID:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B\""

- (void)awakeFromNib
{
	gotPage = NO;
	originalSize = NSMakeSize(movie.frame.size.width, movie.frame.size.height);
	[downloadButton setEnabled:NO];
}

-(IBAction)finishedInput:(id)sender {
	static NSString *httpval = @"\\b(https?)://(?:(\\S+?)(?::(\\S+?))?@)?([a-zA-Z0-9\\-.]+)(?::(\\d+))?((?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!():@\\\\]*)+)?";

	if ([[urlInput stringValue] rangeOfRegex:httpval].location == NSNotFound) {
		[urlInput selectText:sender];
	} else {
		if (![[urlInput stringValue] hasPrefix:@"http://"]) {
			[urlInput setStringValue:[@"http://" stringByAppendingString:[urlInput stringValue]]];
		}
		
		if ([[urlInput stringValue] hasPrefix:@"http://presentur.ntu.edu.sg"]) {
			videolecture = nil;
			videolecture = [[EFVideoLecture alloc] initWithURL:[urlInput stringValue] webViewUserAgent:WEBVIEW_USERAGENT terminatingCondition:CLASSID_TOHUNTFOR];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processVideoLectureNotifications:) name:EFVideoLectureParserEndLoadMetadata object:videolecture];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processVideoLectureNotifications:) name:EFVideoLectureParserDidLoadNotification object:videolecture];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processVideoLectureNotifications:) name:EFVideoLectureParserEndLoadNotification object:videolecture];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processVideoLectureNotifications:) name:EFVideoLectureParserDidCompleteNotification object:videolecture];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processVideoLectureNotifications:) name:EFVideoLectureParserDidFindVideoURLNotification object:videolecture];

			[self closeInput:sender];
			[[NSApplication sharedApplication] beginSheet:progressWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
			[progressIndicator startAnimation:sender];
			
			[videolecture process];
		} else {
			[urlInput selectText:sender];
		}
		
	}
	
}

-(void)processVideoLectureNotifications:(NSNotification *) notification {
	if ([notification name] == EFVideoLectureParserDidLoadNotification) {
		[progressLabel setStringValue:[@"Start load of " stringByAppendingString:[[notification object] currentURL]]];
	} else if ([notification name] == EFVideoLectureParserDidLoadNotification) {
		[progressLabel setStringValue:[@"Finished load of " stringByAppendingString:[[notification object] currentURL]]];
	} else if ([notification name] == EFVideoLectureParserDidFindVideoURLNotification) {
		[progressLabel setStringValue:@"Found video page. Forwarding"];
	} else if ([notification name] == EFVideoLectureParserEndLoadMetadata) {
		[progressLabel setStringValue:@"Found metadata!"];
		[window setTitle:[[[notification object] title] stringByAppendingString:@" - edventurous"]];
		[titleLabel setStringValue:[[notification object] author]];
		
	} else if ([notification name] == EFVideoLectureParserDidCompleteNotification) {

		[progressIndicator stopAnimation:notification];
		[self doneWithSheet:progressWindow withSender:notification];
		
		[movie setMovie:[(EFVideoLecture *)[notification object] movie]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieLoadStateChanged:) name:QTMovieLoadStateDidChangeNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserEndLoadMetadata object:[notification object]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserDidLoadNotification object:[notification object]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserEndLoadNotification object:[notification object]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserDidCompleteNotification object:[notification object]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserDidFindVideoURLNotification object:[notification object]];
		
		NSLog(@"Video URL is: %@", [[notification object] videoURL]);
		
		if ([[(QTMovie *)[[notification object] movie] attributeForKey:QTMovieLoadStateAttribute] longValue] >= QTMovieLoadStateLoaded) {
			originalSize = [self getMovieNaturalSize:movie.movie withOriginal:originalSize];
			[self resizeMovieByx:0];
		}
	}
}

-(void)movieLoadStateChanged:(id)sender {
	NSLog(@"%li %li", [[[movie.movie movieAttributes] valueForKey:QTMovieLoadStateAttribute] longValue], QTMovieLoadStateLoaded);
	
	if (([[movie.movie attributeForKey:QTMovieLoadStateAttribute] longValue] >= QTMovieLoadStateLoaded) && ([[movie.movie attributeForKey:QTMovieLoadStateAttribute] longValue] < QTMovieLoadStateComplete)) {
		NSLog(@"Setting original size");
		originalSize = [self getMovieNaturalSize:movie.movie withOriginal:originalSize];
		[self resizeMovieByx:0];
	}		
	
	if ([[movie.movie attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete) {
		NSLog(@"Done loading movie");
		[downloadButton setEnabled:YES];
	} else {
		NSLog(@"Loading movie");
		[downloadButton setEnabled:NO];
	}
}

-(IBAction) downloadMovie:(id)sender {
	if ([[movie.movie attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete) {
		NSSavePanel *sp;
		int runResult;
		
		/* create or get the shared instance of NSSavePanel */
		sp = [NSSavePanel savePanel];
		
		/* set up new attributes */
		[sp setRequiredFileType:@"mov"];
		
		/* display the NSSavePanel */
		runResult = [sp runModalForDirectory:NSHomeDirectory() file:@""];
		
		/* if successful, save file under designated name */
		if (runResult == NSOKButton) {
			if (![movie.movie writeToFile:[sp filename] withAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:QTMovieFlatten]])
				NSBeep();
		}
	}
	
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
	originalSize = [self getMovieNaturalSize:[movie movie] withOriginal:originalSize];	
	
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
	[videolecture setUrl:@"file:///tmp"];
	NSLog(@"Cancelled processing of pages");
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserEndLoadMetadata object:videolecture];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserDidLoadNotification object:videolecture];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserEndLoadNotification object:videolecture];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserDidCompleteNotification object:videolecture];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EFVideoLectureParserDidFindVideoURLNotification object:videolecture];
	

}

-(IBAction) showURLInputView:(id)sender {

	[[NSApplication sharedApplication] beginSheet:urlInputView modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];

}

-(NSSize)getMovieNaturalSize:(QTMovie *)qtMovie withOriginal:(NSSize)original {
	NSSize finalSize = original;
	NSSize testNaturalSize = [[qtMovie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
	NSSize testCurrentSize = [[qtMovie attributeForKey:QTMovieCurrentSizeAttribute] sizeValue];		
	
	NSLog(@"Getting original size");
	
	if ((testCurrentSize.height != 0) && (testCurrentSize.width != 0)) {
		finalSize = testCurrentSize;
	}		
	
	if ((testNaturalSize.height != 0) && (testNaturalSize.width != 0)) {
		finalSize = testNaturalSize;
	}
	return finalSize;
}



@end
