//
//  AppDelegate.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.09.
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "AppDelegate.h"
#import "DataManager.h"
#import "Settings.h"
#import "Constants.h"
#import "SAPE2ETraceManager.h"

@interface AppDelegate () <UISplitViewControllerDelegate>
@property (strong, nonatomic) id<SAPE2ETraceTransaction> e2ETransaction;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Load the styles for the cutomizable controls, should be called before any MAF* control and MAFLogonUI created
//    [MAFUIStyleParser loadSAPDefaultStyle];
    _window.backgroundColor = [UIColor colorWithRed:117/255.f green:27/255.f blue:99/255.f alpha:1.f];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    [[[SAPSupportabilityFacade sharedManager] getClientLogManager] setLogDestination:(CONSOLE | FILESYSTEM)];
    [[[SAPSupportabilityFacade sharedManager] getClientLogManager] setLogLevel:[Settings sharedInstance].currentLogLevel];
    
    if( [Settings sharedInstance].traceOn )
    {
        NSError* error = nil;
        self.e2ETransaction = [[[SAPSupportabilityFacade sharedManager] getE2ETraceManager] startTransaction:kShowcaseAppE2ETransactionMain error:&error];
        if( error )
        {
            LOGWAR(@"Could not start E2ETransaction. Details: %@", error.localizedDescription);
        }
        else
        {
            [Settings sharedInstance].traceOn = _e2ETransaction ? YES : NO;
        }
    }

//    [self setupSecurity];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    // if background execution is not supported, stop E2ETrace if any
    NSError* error = nil;
    if( [UIApplication sharedApplication].backgroundRefreshStatus != UIBackgroundRefreshStatusAvailable )
    {
        if( [Settings sharedInstance].traceOn && _e2ETransaction )
        {
            [Settings sharedInstance].traceOn = NO;
            
            [[[SAPSupportabilityFacade sharedManager] getE2ETraceManager] endTransaction:_e2ETransaction error:&error];
            if( error )
            {
                LOGERR(@"Could not end E2ETransaction. Details: %@", error.localizedDescription);
            }
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [[DataManager sharedInstance] saveContext];
}

@end
