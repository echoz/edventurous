//
//  edventurousAppDelegate.m
//  edventurous
//
//  Created by Jeremy Foo on 9/10/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import "edventurousAppDelegate.h"

@implementation edventurousAppDelegate
@synthesize window, mainInterface;

-(void)awakeFromNib {

	mainInterface = [[MainInterfaceViewController alloc] initWithNibName:@"MainInterface" bundle:nil];
	[window.contentView addSubview:mainInterface.view];
	
	[mainInterface.view setFrame:[[window contentView] bounds]];
	
	mainInterface.window = self.window;
	
	[[NSApplication sharedApplication] setDelegate:self];
	[[NSApplication sharedApplication] setNextResponder:mainInterface];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication {
	return YES;
}

@end
