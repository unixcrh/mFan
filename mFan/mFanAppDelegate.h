//
//  mFanAppDelegate.h
//  mFan
//
//  Created by yang shengfu on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mFanAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    UITabBarController *tabBarController;

}

+ (void) increaseNetworkActivityIndicator;
+ (void) decreaseNetworkActivityIndicator;

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@end
