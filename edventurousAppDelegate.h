//
//  edventurousAppDelegate.h
//  edventurous
//
//  Created by Jeremy Foo on 9/10/09.
//  Copyright 2009 ORNYX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <QTKit/QTKit.h>
#import "RegexKitLite.h"
#import "MainInterfaceViewController.h"

@interface edventurousAppDelegate : NSObject {
    NSWindow *window;
	MainInterfaceViewController *mainInterface;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) MainInterfaceViewController *mainInterface;

@end
