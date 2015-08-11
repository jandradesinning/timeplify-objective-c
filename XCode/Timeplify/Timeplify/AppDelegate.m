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
#import "Utility.h"

#import "Reachability.h"

@implementation AppDelegate

@synthesize m_arrFavoriteTrains;
@synthesize m_arrFavoriteStations;
@synthesize m_GPSCoordinate;
@synthesize m_iGPSStatus;
@synthesize m_Reachability;


#pragma mark - Train Service Status

-(void) parseTrainServiceStatusResult:(NSDictionary*)IN_Dict
{
    
    NSDictionary* oDict = [IN_Dict objectForKey:@"service"];
    if (oDict == nil) {
        return;
    }
    
    NSDictionary* oDictStatus = [oDict objectForKey:@"data"];
    if (oDictStatus == nil) {
        return;
    }
    
    
    NSString* strFeedTime = [oDict objectForKey:@"feedTime"];
    if (strFeedTime != nil) {
        [Utility saveStringInDefault:@"ALL_SERVICE_STATUSES_FEED_TIME" :strFeedTime];
    }
    
    NSMutableDictionary* oD2 = [[NSMutableDictionary alloc] initWithDictionary:oDictStatus];
    [Utility saveDictInDefault:@"ALL_SERVICE_STATUSES" :oD2];
    
}

-(void) updateTrainServiceStatus
{
    NSMutableDictionary* oDictParam= [[NSMutableDictionary alloc] init];
    [oDictParam setObject:@"1.0" forKey:@"appVersion"];
    
    [PFCloud callFunctionInBackground:@"getServiceStatus" withParameters:oDictParam
                                block:^(id result, NSError *error)
     {
         if (error) {
             
         }
         else
         {
             [self parseTrainServiceStatusResult: result];
             
         }
         
     }];
    
}

-(void) timerUpdateServiceStatusCalled
{
    if (!([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)) {
        return;
    }
    
    [self updateTrainServiceStatus];
    
    
}


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
	   
    
    
    
    if ((newLocation.coordinate.latitude > 8.0)&&
        (newLocation.coordinate.latitude < 9.0)){
        
        if (m_bInitalStationShown == NO) {
            // TEST_CODE
            CLLocationCoordinate2D oLoc = CLLocationCoordinate2DMake(INT_TESTING_LATITUDE, INT_TESTING_LONGITUDE); // Near 6   610 - morrison AV Sound View
            m_GPSCoordinate=oLoc;
            // TEST_CODE
        }
        
    }
    else
    {
        m_GPSCoordinate = newLocation.coordinate;
    }
    
	m_iGPSStatus = 2;
    
    
    double dbDist =  [Utility getLocationDistance:m_GPSCoordinate.latitude
                                                                :m_GPSCoordinate.longitude
                                                                :m_PrevGPSCoordinate.latitude
                                                                :m_PrevGPSCoordinate.longitude];
    if (dbDist > INT_GPS_NOTIFY_MIN_DISTANCE) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_SIGNIFICANT_GPS_CHANGE" object:nil];
        m_PrevGPSCoordinate = m_GPSCoordinate;
    }
    
    
    if (m_bInitalStationShown == NO) {
        
        m_bInitalStationShown = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_ALL_SET_INITIALLY" object:nil];
        
    }

}


- (void)locationManager: (CLLocationManager *)manager
	   didFailWithError: (NSError *)error
{
	//NSLog(@"locationManager failed");
    
    m_iGPSStatus = 1;
    
    
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
    
    if ([m_LocationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {        
        // TEST_CODE
        [m_LocationManager requestWhenInUseAuthorization];
    }
    

}

#pragma mark - No Idle


- (void) ScreenDimTimerCalled
{
	UIApplication *thisApp = [UIApplication sharedApplication];
	thisApp.idleTimerDisabled = NO;
	thisApp.idleTimerDisabled = YES;
	
}


#pragma mark - Others

-(void) setUpReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    m_Reachability = [Reachability reachabilityForInternetConnection];
    [m_Reachability startNotifier];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_REACHABILITY_CHANGED" object:nil];
    
}

- (void) reachabilityChanged:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_REACHABILITY_CHANGED" object:nil];
}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    m_bInitalStationShown = NO;
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    if ([Utility isDeviceiPhone5]) {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_5" bundle:nil];
    }
    else
    {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    }
    
    
    self.viewController.m_VCFlipParent = nil;
    self.viewController.m_bDummyFlip = NO;
    
    
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
    
    
    
    [self setUpReachability];
    
    
    [NSTimer scheduledTimerWithTimeInterval:INT_UPDATE_SERVICE_STATUS_DELAY target:self selector:@selector(timerUpdateServiceStatusCalled) userInfo:nil repeats:YES];
    
    
    
	[NSTimer scheduledTimerWithTimeInterval:5.0 target:self
								   selector:@selector(ScreenDimTimerCalled) userInfo:nil repeats:YES];

    
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
    
    if (m_Reachability.currentReachabilityStatus == NotReachable) {
        //NSLog(@"Internet not reachable");
        return;
    }else if(m_bInitalStationShown == YES){
                [self startGPS];
                [self.viewController getNearestStation];
    }
    
    [self updateTrainServiceStatus];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
