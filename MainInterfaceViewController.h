//
//  MainInterfaceViewController.h
//  edventurous
//
//  Created by Jeremy Foo on 9/11/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "SignatureEngine.h"
#import <QTKit/QTKit.h>
#import "RegexKitLite.h"

@interface MainInterfaceViewController : NSViewController {
	WebView *webv;
	BOOL gotPage;
	SignatureEngine *sigEngine;
	IBOutlet NSTextField *urlInput;
	IBOutlet NSWindow *urlInputView;
	IBOutlet NSTextField *titleLabel;
	IBOutlet NSTextField *progressLabel;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSWindow *progressWindow;
	NSWindow *window;
	IBOutlet QTMovieView *movie;
}

@property (nonatomic) WebView *webv;
@property (nonatomic, retain) SignatureEngine * sigEngine;
@property (nonatomic, retain) NSWindow *window;

-(void)doneWithSheet:(NSWindow *)sheet withSender:(id)sender;

@property (nonatomic, retain) IBOutlet QTMovieView *movie;
@property (nonatomic, retain) IBOutlet NSTextField *progressLabel;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) IBOutlet NSWindow *progressWindow;
@property (nonatomic, retain) IBOutlet NSTextField *urlInput;
@property (nonatomic, retain) IBOutlet NSWindow *urlInputView;
@property (nonatomic, retain) IBOutlet NSTextField *titleLabel;
-(IBAction) finishedInput:(id)sender;
-(IBAction) showURLInputView:(id)sender;
-(IBAction) closeInput:(id)sender;
-(IBAction)cancelProcessing:(id)sender;
@end
