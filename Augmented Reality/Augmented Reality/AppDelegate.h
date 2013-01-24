//
//  AppDelegate.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <UIKit/UIKit.h>

// --- Defines --- ;
// AppDelegate Class ;
@interface AppDelegate : UIResponder < UIApplicationDelegate >

// Properties ;
@property ( nonatomic, retain ) UIWindow*           window ;
@property ( nonatomic, retain ) UIViewController*   viewController ;

// Functions ;
+ ( AppDelegate* ) sharedDelegate ;

@end
