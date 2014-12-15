//
//  AppDelegate.h
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

{
    NSMutableArray* m_arrFavoriteTrains;
    CLLocationManager *m_LocationManager;
	CLLocationCoordinate2D m_GPSCoordinate;
	int m_iGPSStatus;

    
}
-(void) stopGPS;
-(void) startGPS;
- (void) initGPS;

@property (readwrite,assign) int m_iGPSStatus;
@property (readwrite,assign) CLLocationCoordinate2D m_GPSCoordinate;

@property (strong, nonatomic) NSMutableArray* m_arrFavoriteTrains;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@end
