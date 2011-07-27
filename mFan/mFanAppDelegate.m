//
//  mFanAppDelegate.m
//  mFan
//
//  Created by yang shengfu on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "mFanAppDelegate.h"
#import "NavigationRotateController.h"
#import "MGTwitterEngine.h"
#import "HomeViewController.h"
#import "LoginController.h"
#import "RepliesListController.h"
#import "DirectMessagesController.h"
#import "FollowersController.h"


static int NetworkActivityIndicatorCounter = 0;

@implementation mFanAppDelegate


@synthesize window;

@synthesize tabBarController;


- (UINavigationController *)createNavControllerWrappingViewControllerOfClass:(Class)cntrloller 
                                                                     nibName:(NSString*)nibName 
                                                                 tabIconName:(NSString*)iconName
                                                                    tabTitle:(NSString*)tabTitle
{
	UIViewController* viewController = [[cntrloller alloc] initWithNibName:nibName bundle:nil];
	
	NavigationRotateController *theNavigationController;
	theNavigationController = [[NavigationRotateController alloc] initWithRootViewController:viewController];
	viewController.tabBarItem.image = [UIImage imageNamed:iconName];
	viewController.title = NSLocalizedString(tabTitle, @""); 
	[viewController release];
	
	return theNavigationController;
}

- (void)setupPortraitUserInterface 
{
	UINavigationController *localNavigationController;
	
    // **************  Test 1 Capacity ******
	NSMutableArray *localViewControllersArray = [[NSMutableArray alloc] initWithCapacity:1];
     
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass:[HomeViewController class] nibName:nil tabIconName:@"HomeTabIcon.tiff" tabTitle:@"Home"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController  release];
	if([MGTwitterEngine username] == nil)
		[LoginController showModeless:localNavigationController animated:NO];
    
    localNavigationController = [self createNavControllerWrappingViewControllerOfClass:[RepliesListController class] nibName:@"UserMessageList" tabIconName:@"Replies.tiff" tabTitle:@"Replies"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass:[DirectMessagesController class] nibName:@"UserMessageList" tabIconName:@"Messages.tiff" tabTitle:@"Messages"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	/*localNavigationController = [self createNavControllerWrappingViewControllerOfClass:[TweetQueueController class] nibName:@"TweetQueue" tabIconName:@"Queue.tiff" tabTitle:[TweetQueueController queueTitle]];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release]; */
    
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass:[FollowersController class] nibName:@"UserMessageList" tabIconName:@"followers.tiff" tabTitle:@"Followers"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass:[FollowingController class] nibName:@"UserMessageList" tabIconName:@"following.tiff" tabTitle:@"Following"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	/*localNavigationController = [self createNavControllerWrappingViewControllerOfClass:[SettingsController class] nibName:@"SettingsView" tabIconName:@"SettingsTabIcon.tiff" tabTitle:@"Settings"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass:[AboutController class] nibName:@"About" tabIconName:@"About.tiff" tabTitle:@"About"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release]; */
	
	tabBarController.viewControllers = localViewControllersArray;
	
	[localViewControllersArray release];
	
}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // Add the tab bar controller's current view as a subview of the window
    
	[self setupPortraitUserInterface];
    [window addSubview:tabBarController.view];
    
	// [[LocationManager locationManager] startUpdates];
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [tabBarController release];
    [window release];
    [super dealloc];
}

+ (void) increaseNetworkActivityIndicator
{
	NetworkActivityIndicatorCounter++;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NetworkActivityIndicatorCounter > 0;
}

+ (void) decreaseNetworkActivityIndicator
{
	NetworkActivityIndicatorCounter--;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NetworkActivityIndicatorCounter > 0;
}


/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
