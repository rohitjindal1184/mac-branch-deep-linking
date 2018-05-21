//
//  APPAppDelegate.m
//  TestBed-Mac
//
//  Created by Edward Smith on 5/15/18.
//  Copyright © 2018 Edward Smith. All rights reserved.
//

#import "APPAppDelegate.h"
#import "APPViewController.h"
#import <Branch/Branch.h>

#include "Branch/BNCLog.h"

@interface APPAppDelegate ()
@property (strong, nonatomic) APPViewController*viewController;
@end

@implementation APPAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    BranchConfiguration*configuration = [[BranchConfiguration alloc] init];
    configuration.key = @"key_live_glvYEcNtDkb7wNgLWwni2jofEwpCeQ3N";
    [[Branch sharedInstance] startWithConfiguration:configuration];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(openedURLNotification:)
        name:BranchDidOpenURLWithSessionNotification
        object:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.viewController = [APPViewController loadController];
    [self.viewController.window makeKeyAndOrderFront:self];
}

- (BOOL)application:(NSApplication *)application
willContinueUserActivityWithType:(NSString *)userActivityType {
    BNCLogMethodName();
    return YES;
}

- (BOOL)application:(NSApplication *)application
        continueUserActivity:(NSUserActivity *)userActivity
        restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    BNCLogMethodName();
    return YES;
}

- (void) openedURLNotification:(NSNotification*)notification {
    BranchSession*session = notification.userInfo[BranchSessionKey];
    NSString*message = session.data[@"message"];
    NSAlert* alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = @"Opened URL";
    alert.informativeText = message;
    [alert runModal];
}

#if 0
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    BNCPerformBlockOnMainThreadAsync(^{
        BNCLogMethodName();
        NSAlert* alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = @"Open URL";
        alert.informativeText = [NSString stringWithFormat:@"%@", urls];
        [alert runModal];
    });
}
#endif

@end