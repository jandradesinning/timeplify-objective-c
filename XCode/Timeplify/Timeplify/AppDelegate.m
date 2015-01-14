//
//  AppDelegate.m
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

#import "Defines.h"

#import "DataManager.h"

@implementation AppDelegate

@synthesize m_arrFavoriteTrains;
@synthesize m_arrFavoriteStations;
@synthesize m_GPSCoordinate;
@synthesize m_iGPSStatus;


#pragma mark - GPS

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if ([locations count] < 1) {
        return;
    }
    
    CLLocation* newLocation = [locations lastObject];
	NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
	if (locationAge > 5.0)
    {
        return;
    }
    
//	NSLog(@"Latitude = %f Longitude = %f Acuracy %f %f",newLocation.coordinate.latitude,newLocation.coordinate.longitude, newLocation.horizontalAccuracy, newLocation.verticalAccuracy);
	   
    
	m_GPSCoordinate = newLocation.coordinate;
	m_iGPSStatus = 2;
	
    
    
}



- (void)locationManager: (CLLocationManager *)manager
	   didFailWithError: (NSError *)error
{
	NSLog(@"locationManager failed");
    
    m_iGPSStatus = 1;
    
      
    // TEST_CODE
    CLLocationCoordinate2D oLoc = CLLocationCoordinate2DMake(INT_TESTING_LATITUDE, INT_TESTING_LONGITUDE); // Near 6   610 - morrison AV Sound View
    m_GPSCoordinate=oLoc;
    m_iGPSStatus = 2;
    // TEST_CODE

   	
}

-(void) startGPS
{
    [m_LocationManager stopUpdatingLocation];
    [m_LocationManager startUpdatingLocation];
}

-(void) stopGPS
{
    [m_LocationManager stopUpdatingLocation];
}

- (void) initGPS
{
 	
	m_iGPSStatus = 0;
	m_LocationManager = [[CLLocationManager alloc] init];
	m_LocationManager.desiredAccuracy = kCLLocationAccuracyBest;
    m_LocationManager.activityType = CLActivityTypeFitness;
	m_LocationManager.delegate = self;
}

#pragma mark - Others


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    
    [DataManager checkAndCopyDatabase];
    
    [Parse setApplicationId:STR_PARSE_APP_ID  clientKey:STR_PARSE_CLIENT_KEY];
    
    
    m_arrFavoriteTrains = [[NSMutableArray alloc] init];
    m_arrFavoriteStations = [[NSMutableArray alloc] init];
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:self.viewController ];
    navigationController.navigationBarHidden = YES;
    self.window.rootViewController = navigationController;
    
    [self initGPS];
    [self startGPS];
    
    //self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [self startGPS];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
