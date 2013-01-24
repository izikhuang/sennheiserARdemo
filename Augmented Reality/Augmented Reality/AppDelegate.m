//
//  AppDelegate.m
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import "AppDelegate.h"
#import "ARScanController.h"

// --- Defines --- ;
// AppDelegate Class ;
@implementation AppDelegate

// Properties ;
@synthesize window          = _window ;
@synthesize viewController  = _viewController ;

// Functions ;
#pragma mark - Shared Functions
+ ( AppDelegate* ) sharedDelegate
{
    return ( AppDelegate* )[ [ UIApplication sharedApplication ] delegate ] ;
}

#pragma mark - UIApplication
- ( void ) dealloc
{
    // Release ;
    [ _window release ] ;
    [ _viewController release ] ;
    
    [ super dealloc ] ;
}

- ( BOOL ) application : ( UIApplication* ) _application didFinishLaunchingWithOptions : ( NSDictionary* ) _launchOptions
{
    self.window         = [ [ [ UIWindow alloc ] initWithFrame : [ [ UIScreen mainScreen ] bounds ] ] autorelease ] ;
    self.viewController = [ ARScanController sharedController ] ;
    
    [ self.window setRootViewController : self.viewController ] ;
    [ self.window makeKeyAndVisible ] ;
    return YES ;
}

- ( void ) applicationWillResignActive : ( UIApplication* ) _application
{
    
}

- ( void ) applicationDidEnterBackground : ( UIApplication* ) _application
{
    
}

- ( void ) applicationWillEnterForeground : ( UIApplication* ) _application
{
    
}

- ( void ) applicationDidBecomeActive : ( UIApplication* ) _application
{
    
}

- ( void ) applicationWillTerminate : ( UIApplication* ) _application
{
    
}

@end
