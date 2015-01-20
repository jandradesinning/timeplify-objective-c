//
//  ViewController.m
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "ViewController.h"
#import "TrainSelectViewController.h"
#import "StationSelectViewController.h"
#import "AllSetViewController.h"
#import "FavoritesViewController.h"
#import "AboutViewController.h"
#import "GPSTestViewController.h"

#import "LeftMenuView.h"
#import "Defines.h"
#import "Utility.h"
#import "GlobalCaller.h"

#import "ST_Train.h"
#import "ST_Station.h"

#import "NearestStation.h"
#import "Direction2View.h"
#import "StatusUtility.h"

#import "AppDelegate.h"

#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()

@end

@implementation ViewController




-(void) showAbout
{
    AboutViewController* viewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    
    
    [self.navigationController pushViewController:viewController animated:YES];
    
}

-(void) showStationSelect:(int) IN_iMode
{
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    viewController.m_iScreenMode = IN_iMode;
    
    
    [self.navigationController pushViewController:viewController animated:YES];

}

-(void) showFavorites
{
    FavoritesViewController* viewController = [[FavoritesViewController alloc] initWithNibName:@"FavoritesViewController" bundle:nil];
   
    
    [self.navigationController pushViewController:viewController animated:YES];
    
}

#pragma mark VibrateAlert

-(void) vibrateTimerCalled
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    m_iVibrateCalls++;
    
    if (m_iVibrateCalls > 4) {
        if (m_timerVibrate != nil) {
            [m_timerVibrate invalidate];
            m_timerVibrate = nil;
        }
    }
}

-(void) doVibrateAlert
{
    if (m_bTimerChanged == NO) {
        return;
    }
    
    
    if (m_timerVibrate != nil) {
        [m_timerVibrate invalidate];
        m_timerVibrate = nil;
    }
    
    m_iVibrateCalls = 1;
    m_timerVibrate = [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(vibrateTimerCalled)
                                   userInfo:nil
                                    repeats:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Timeplify"
                                                    message:@"You must start walking now to catch the next train."
                                                   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    
    [alert show];

}

#pragma mark Timer Updation

    
-(void) timerUpdationCalled
{
    [self setStatusValues];
    
    m_bTimerChanged = YES;
}

-(void) timerWalkDistanceCalled
{
    
    [self getWalkingDistance];
}

#pragma mark Walking Distance

-(void) mainThreadAfterWalkingDistance:(NSData*) IN_Data
{
    m_ctrlLblWalkingDistance.text = @"";
    
    if (IN_Data == nil) {
        return;
    }
    
    NSDictionary *locDict = [NSJSONSerialization JSONObjectWithData:IN_Data options:kNilOptions error:nil];
    
    if (locDict == nil) {
        return;
    }
        
    StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
    
    m_iWalkingDistance = [oStatusUtil getWalkingDistanceInSecs:locDict];
    NSString* strTime = [oStatusUtil getWalkingDistance:locDict];
    m_ctrlLblWalkingDistance.text = strTime;
       
}

-(void) getWalkingDistanceInBackground:(NSString*)IN_strUrl
{

    NSData *locData = [NSData dataWithContentsOfURL:[NSURL URLWithString:IN_strUrl]];
    
    
    [self performSelectorOnMainThread:@selector(mainThreadAfterWalkingDistance:) withObject:locData waitUntilDone:YES];
    
	CFRunLoopRun();
    
}

-(void) getWalkingDistance
{
    
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    if (appDel.m_iGPSStatus != 2)
    {
        return;
    }
    if (m_curStation == nil) {
        return;
    }
    
    NSString *strURL = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/distancematrix/json?origins=%f,%f&destinations=%f,%f&mode=walking&language=en-EN&sensor=false",
                        appDel.m_GPSCoordinate.latitude,
                        appDel.m_GPSCoordinate.longitude,
                        m_curStation.m_dbLatitude, m_curStation.m_dbLongitude];
                        
    
    [self performSelectorInBackground:@selector(getWalkingDistanceInBackground:) withObject:strURL];
}

#pragma mark DirectionView


- (void)animationToShowDirection2ViewStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
}

- (void)animationToHideDirection2ViewStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
    m_Direction2View.hidden = YES;
}


-(void) showDirection2View:(ST_Station*)IN_Station :(double) IN_dbAnimDuration
{
    m_Direction2View.m_Station = IN_Station;
    [m_Direction2View setValues];
    
    m_Direction2View.hidden = NO;
    m_Direction2View.alpha = 0.0;
    m_Direction2View.center = self.view.center;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:IN_dbAnimDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToShowDirection2ViewStopped:finished:context:)];
    
    m_Direction2View.alpha = 1.0;
    
    [UIView commitAnimations];
    
}

-(void) hideDirection2View
{
    
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToHideDirection2ViewStopped:finished:context:)];
    
    m_Direction2View.alpha = 0.0;
    
    [UIView commitAnimations];
    
}

-(Direction2View*) getDirection2View
{
    Direction2View* oView = nil;
    
    NSArray *topLevelObjects;
    
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"Direction2View" owner:self options:nil];
    
	for (id currentObject in topLevelObjects){
		if ([currentObject isKindOfClass:[Direction2View class]]){
			oView =  (Direction2View *) currentObject;
			break;
		}
	}
    return oView;
}

-(void)handleDirection2Selected:(NSNotification *)pNotification
{
    [self hideDirection2View];
    [self makeBusy];
    
    m_curStation = m_Direction2View.m_Station;
    m_curStation.m_iTemporaryDirection = m_curStation.m_iSelectedDirection;
    [self getTrainStatus];
    
    
    
}

#pragma mark LeftMenu


-(void) moveSubViewsToRight:(double) IN_dbDist
{
    for (int i= 0; i < [self.view.subviews count]; i++) {
        UIView* oV = [self.view.subviews objectAtIndex:i];
        
        CGRect oRct = oV.frame;
        oRct.origin.x += IN_dbDist;
        oV.frame = oRct;
    }
}


- (void)animationToShowLeftMenuStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
}

- (void)animationToHideLeftMenuStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
    m_LeftMenuView.hidden = YES;
    m_dbLeftNavMovedDist = 0;
}


-(void) showLeftMenu
{
    
    if (m_LeftMenuView.hidden == NO) {
        return;
    }
    
    m_LeftMenuView.hidden = NO;
    m_dbLeftNavMovedDist = INT_LEFT_NAV_MOVE_DISTANCE;
    m_LeftMenuView.m_arrNextTrains = m_arrNextTrains;
    [m_LeftMenuView setValues];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToShowLeftMenuStopped:finished:context:)];
    
    [self moveSubViewsToRight:m_dbLeftNavMovedDist];
    
    [UIView commitAnimations];
    
    
}

-(void) hideLeftMenu
{
    double dbDist = -(m_dbLeftNavMovedDist);
    
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToHideLeftMenuStopped:finished:context:)];
    
    [self moveSubViewsToRight:dbDist];
    
    [UIView commitAnimations];
    
}

-(LeftMenuView*) getLeftMenuView
{
    LeftMenuView* oView = nil;
    
    NSArray *topLevelObjects;
    
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"LeftMenuView" owner:self options:nil];
    
	for (id currentObject in topLevelObjects){
		if ([currentObject isKindOfClass:[LeftMenuView class]]){
			oView =  (LeftMenuView *) currentObject;
			break;
		}
	}
    return oView;
}



-(void)handleHideLeftMenuView:(NSNotification *)pNotification
{
    [self hideLeftMenu];
}


-(void)handleLeftMenuSelected:(NSNotification *)pNotification
{
    NSIndexPath* oInd = [pNotification object];
    if (oInd.row == 0) {
        [self showStationSelect:INT_STATION_SEL_FROM_SEE_ALL];
    }
    
    if (oInd.row == 1) {
        [self showFavorites];
    }
    
    if (oInd.row == 2) {
        [self showAbout];
    }
    
    [self hideLeftMenu];
}



#pragma mark Get Status

-(void) clearStatusValues
{
    m_iCurrentTrainPos = -1;
    m_ctrlLblService.text = @"";
    m_ctrlLblDataType.text = @"";
    m_ctrlLblMainTimeValue.text = @"0";
    m_ctrlLblMainTimeUnit.text = @"";
    m_ctrlLblNextTime.text = @"";
    m_ctrlLblStation.text = @"";
    m_ctrlLblDirection.text = @"";
    m_ctrlImgViewTrain.image = nil;
}

-(void) setServiceStatus:(NSMutableDictionary*)IN_Dict
{
    NSString* strTxt = [IN_Dict objectForKey:@"serviceStatus"];
    m_ctrlLblService.text = strTxt;
    
    UIColor* oClr = [UIColor whiteColor];
    
    NSString* strLower = [strTxt lowercaseString];
    if ([strLower isEqualToString:@"suspended"]) {
        oClr = [UIColor colorWithRed:(153.0/255.0) green:(102.0/255.0) blue:(0.0/255.0) alpha:1.0];
    }
    
    if ([strLower isEqualToString:@"delays"]) {
        oClr = [UIColor colorWithRed:(153.0/255.0) green:(0.0/255.0) blue:(51.0/255.0) alpha:1.0];
    }

    if ([strLower isEqualToString:@"goodservice"]) {
        oClr = [UIColor colorWithRed:(0.0/255.0) green:(102.0/255.0) blue:(0.0/255.0) alpha:1.0];
    }

    if ([strLower isEqualToString:@"plannedwork"]) {
        oClr = [UIColor colorWithRed:(153.0/255.0) green:(102.0/255.0) blue:(0.0/255.0) alpha:1.0];
    }

    if ([strLower isEqualToString:@"servicechange"]) {
        oClr = [UIColor colorWithRed:(153.0/255.0) green:(102.0/255.0) blue:(0.0/255.0) alpha:1.0];
    }

    m_ctrlLblService.textColor = oClr;
}

-(void) setStatusValues
{
    
    if (m_iCurrentTrainPos < 0) {
        return;
    }
    
    if ([m_arrNextTrains count] < 1) {
        return;
    }
    
    NSMutableDictionary* oDict = [m_arrNextTrains objectAtIndex:m_iCurrentTrainPos];
    NSString* strRoute = [oDict objectForKey:@"routeId"];
    if (strRoute == nil) {
        return;
    }
    
    NSString* strNormalImage = [NSString stringWithFormat:@"vehicle-logo-%@.png", strRoute];
    m_ctrlImgViewTrain.image = [UIImage imageNamed:strNormalImage];
    
    m_ctrlLblStation.text = m_curStation.m_strStationName;
    
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        m_ctrlLblDirection.text = m_curStation.m_strNorthDirection;
    }
    
    
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        m_ctrlLblDirection.text = m_curStation.m_strSouthDirection;
    }
    
    NSString* strReal = [oDict objectForKey:@"REAL_TIME"];
    if ([strReal isEqualToString:@"YES"]) {
        m_ctrlLblDataType.text = @"Realtime Data";
    }
    else
    {
        m_ctrlLblDataType.text = @"Scheduled Data";
    }
    
    [self setServiceStatus:oDict];
    
    StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
    
    int iTimeRemaining = [oStatusUtil getTimeRemainingInSecs:oDict];
    if (iTimeRemaining < m_iWalkingDistance) {
        if (m_iVibrateCalls < 1) {
            [self doVibrateAlert];
        }
        
    }
    
    
    NSString* strTime = [oStatusUtil getTimeRemaining:oDict];
    
    if ([strTime length] < 1) {
        [self clearStatusValues];
        if ([m_arrNextTrains count] > 0) {
            [m_arrNextTrains removeObjectAtIndex:0];
        }
        
        if ([m_arrNextTrains count] > 0) {
            m_iCurrentTrainPos = 0;
        }
        [self setStatusValues];
        return;
    }
    
    NSString* strTimeOnly = [oStatusUtil getTimeOnlyFromFormattedSecs:strTime];
    NSString* strUnit = [oStatusUtil getUnitOnlyFromFormattedSecs:strTime];
    
    
    
    m_ctrlLblMainTimeValue.text = strTimeOnly;
    m_ctrlLblMainTimeUnit.text = strUnit;
    
    
    NSString* strNextTime = [oStatusUtil getNextTimeRemaining:m_arrNextTrains :m_iCurrentTrainPos];
    m_ctrlLblNextTime.text = strNextTime;
}

- (void)animationToReadyStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
    m_viewDim.hidden = YES;
    m_ctrlActivity.hidden = YES;
}

- (void)animationToBusyStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {

}


-(void) makeReady
{
    
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToReadyStopped:finished:context:)];
    
    m_viewDim.alpha = 0.0;
    
    [UIView commitAnimations];
}

-(void) makeBusy
{
    m_viewDim.hidden = NO;
    m_ctrlActivity.hidden = NO;
    m_viewDim.alpha = 0.0;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToBusyStopped:finished:context:)];
    
    m_viewDim.alpha = 0.75;
    
    [UIView commitAnimations];
}

-(void) displayError:(NSString*)IN_strMsg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Timeplify"
													message:IN_strMsg
												   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
	
	[alert show];
    
    
}




-(void)parseStatusServerResponse:(NSDictionary*)IN_Dict :(BOOL) IN_bUsingLocal
{

    
    
    NSDictionary* oDict = IN_Dict;
    
    StatusUtility* oUtil = [[StatusUtility alloc]   init];
    if (IN_bUsingLocal == NO) {
        [oUtil saveScheduledData:oDict :m_curStation];
    }
    else
    {
        oDict = [oUtil getScheduledData:m_curStation];
        if (oDict == nil) {
            return;
        }
    }
    
    
    
    if (!([oDict isKindOfClass:[NSDictionary class]])) {
        [self displayError:@"Invalid response from server"];
        return;
    }
   
    NSLog(@"Dict '%@'", oDict);
    
    m_arrNextTrains = [oUtil getFormattedStatusResult:oDict:IN_bUsingLocal];
    
   
    if ([m_arrNextTrains count] > 0) {
        m_iCurrentTrainPos = 0;
        m_iVibrateCalls = 0;
    }
    
    [self setStatusValues];
}

-(void) getTrainStatus
{
    
    [self clearStatusValues];
    
    m_iCurrentTrainPos = -1;
    [m_arrNextTrains removeAllObjects];
    
    ST_Station* oStation = m_curStation;
    
    
    [self getWalkingDistance];
    
    NSString* strDirection = @"";
    if (oStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        strDirection = @"N";
    }
    
    if (oStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        strDirection = @"S";
    }

    
    NSMutableDictionary* oDictParam= [[NSMutableDictionary alloc] init];
    [oDictParam setObject:@"1.0" forKey:@"appVersion"];
  //  [oDictParam setObject:@"6" forKey:@"route"];
    [oDictParam setObject:oStation.m_strStationId forKey:@"station"];
    [oDictParam setObject:strDirection forKey:@"direction"];
    [oDictParam setObject:[NSNumber numberWithBool:YES] forKey:@"fetchScheduledData"];
    
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:oDictParam
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString* strPostParam = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSLog(@"JSON '%@'", strPostParam);
    
    [PFCloud callFunctionInBackground:@"getStatus" withParameters:oDictParam
                                block:^(id result, NSError *error)
     {
         
         
         if (error) {
             
             if ([error code] == 100) {
                 [self displayError:@"We’re unable to connect to Timeplify Servers, please check your connection and try again to receive live updates."];
                 
                 [self parseStatusServerResponse: nil :YES];
             }
             else
             {
                 
                 [self displayError:[error localizedDescription]];
             }
             
         }
         else
         {
             [self parseStatusServerResponse: result :NO];
         }
         
         [self makeReady];
         
         NSLog(@"Over");
         
     }];
    
    
    NSLog(@"Called");
}


-(void) getDelayedNearestStation
{
    NearestStation* oNear = [[NearestStation alloc] init];
    ST_Station* oStation = [oNear getFirstNearestStation];

    if (oStation == nil) {
        [self displayError:@"We’re unable to find stations within a radius of 3 miles. Please select your station from the available list."];
        [self makeReady];
        return;
    }
    
    
    
    BOOL bHasDirection = NO;
    if (oStation.m_iSelectedDirection == INT_DIRECTION_NORTH) {
        bHasDirection = YES;
    }
    if (oStation.m_iSelectedDirection == INT_DIRECTION_SOUTH) {
        bHasDirection = YES;
    }
    
    
    if (bHasDirection == NO) {
        if ([oStation.m_strSouthDirection length] < 1) {
            
            m_curStation = oStation;
            m_curStation.m_iTemporaryDirection = INT_DIRECTION_NORTH;
            
            [self getTrainStatus];
            return;
        }
        
        if ([oStation.m_strNorthDirection length] < 1) {
            
            m_curStation = oStation;
            m_curStation.m_iTemporaryDirection = INT_DIRECTION_SOUTH;
            
            [self getTrainStatus];
            return;
        }
    }
    
    
    
    if (bHasDirection == NO) {
        m_ctrlActivity.hidden = YES;
        [self showDirection2View:oStation:0.3];
        return;
    }
    

    m_curStation = oStation;
    m_curStation.m_iTemporaryDirection = m_curStation.m_iSelectedDirection;
    
    [self getTrainStatus];

}

-(void) getNearestStation
{
    [self makeBusy];
    
    [self performSelector:@selector(getDelayedNearestStation) withObject:nil afterDelay:0.0];
}


#pragma mark Others



-(void) checkAndDisplayConfigScreens:(BOOL)IN_bAnimated
{
    
    
    
    NSArray* oArr = (NSArray*) [Utility getObjectFromDefault:STR_KEY_FAV_TRAINS];
    if (oArr != nil) {
        NSMutableArray* oArrFavTrains = [GlobalCaller getFavTrainsArray];
        [oArrFavTrains removeAllObjects];
        [oArrFavTrains addObjectsFromArray:oArr];
        
        
        NSArray* oArr2 = (NSArray*) [Utility getObjectFromDefault:STR_KEY_FAV_STATIONS];
        NSMutableArray* oArrFavStations = [GlobalCaller getFavStationsArray];
        [oArrFavStations removeAllObjects];
        [oArrFavStations addObjectsFromArray:oArr2];        
        return;
    }
    

    

    TrainSelectViewController* viewController = [[TrainSelectViewController alloc] initWithNibName:@"TrainSelectViewController" bundle:nil];
    
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:IN_bAnimated completion:nil];

    
    
    
    
    /*
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    viewController.m_iScreenMode = INT_STATION_SEL_FROM_WELOCOME;
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:IN_bAnimated completion:nil];
    */
    
    /*
    AllSetViewController* viewController = [[AllSetViewController alloc] initWithNibName:@"AllSetViewController" bundle:nil];
    
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:IN_bAnimated completion:nil];
     */
    
    
    /*
    FavoritesViewController* viewController = [[FavoritesViewController alloc] initWithNibName:@"FavoritesViewController" bundle:nil];
    
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:IN_bAnimated completion:nil];
     */
}






-(IBAction) btnMenuClicked:(id)sender
{
    [self showLeftMenu];
}

-(IBAction) btnGPSClicked:(id)sender
{
    
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    if (appDel.m_iGPSStatus != 2)
    {
        BOOL locationAllowed = [CLLocationManager locationServicesEnabled];
        if (locationAllowed ==NO)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"LOCATION NOT FOUND"
                                                            message:@"Go to settings and enable location services if you wish to see the nearest stations to you."
                                                           delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            
            [alert show];
            
            
        }

        return;
    }
    
    
    m_bTimerChanged = NO;
    [self getNearestStation];
}

-(IBAction) btnMChangeDirectionClicked:(id)sender
{
    NSLog(@"btnMChangeDirectionClicked");
    
    if (m_curStation == nil) {
        return;
    }
    
    NSLog(@"Bound '%@' '%@'", m_curStation.m_strNorthDirection, m_curStation.m_strSouthDirection);
    
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        
        if ([m_curStation.m_strSouthDirection length] < 1) {
            return;
        }
        
        
        m_curStation.m_iTemporaryDirection = INT_DIRECTION_SOUTH;
    }
    else
    {
        if ([m_curStation.m_strNorthDirection length] < 1) {
            return;
        }
        
        m_curStation.m_iTemporaryDirection = INT_DIRECTION_NORTH;
    }
  
    [self makeBusy];
    [self getTrainStatus];
    
}

-(IBAction) btnLeftArrowClicked:(id)sender
{
    if (m_curStation == nil) {
        return;
    }
    
    NearestStation* oNear = [[NearestStation alloc] init];
    
    ST_Station* oStation = [oNear getPrevStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    if (oStation == nil) {
        return;
    }
    
    [self makeBusy];
    
    oStation.m_iTemporaryDirection = m_curStation.m_iTemporaryDirection;
    m_curStation = oStation;
    [self getTrainStatus];
    

}

-(IBAction) btnRightArrowClicked:(id)sender
{
    if (m_curStation == nil) {
        return;
    }
    
    NearestStation* oNear = [[NearestStation alloc] init];
    
    ST_Station* oStation = [oNear getNextStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    if (oStation == nil) {
        return;
    }
    
    [self makeBusy];
    
    oStation.m_iTemporaryDirection = m_curStation.m_iTemporaryDirection;
    m_curStation = oStation;
    [self getTrainStatus];
}

-(IBAction) btnTestGPSClicked:(id)sender
{
    GPSTestViewController* viewController = [[GPSTestViewController alloc] initWithNibName:@"GPSTestViewController" bundle:nil];
    
    
    [self.navigationController pushViewController:viewController animated:YES];

}

-(void) arrangeHideView
{
    CGRect oRct = m_ctrlViewHide.frame;
    oRct.size.height = self.view.frame.size.height - oRct.origin.y;
    oRct.size.width = self.view.frame.size.width;
    m_ctrlViewHide.frame = oRct;
    
}


-(void) viewWillAppear:(BOOL)animated
{
    m_viewDim.frame = self.view.frame;
    m_Direction2View.frame = self.view.frame;
    
    CGRect oRct = m_LeftMenuView.frame;
    oRct.size.height = self.view.frame.size.height;
    m_LeftMenuView.frame = oRct;
    
    [self arrangeHideView];
}

-(void)handleOneAllStationSelected:(NSNotification *)pNotification
{
    ST_Station* oStation = [pNotification object];
    
    NSLog(@"handleOneAllStationSelected '%@'", oStation.m_strStationName);
    
    if ([oStation.m_strSouthDirection length] < 1) {
        
        [self makeBusy];
        m_curStation = oStation;
        m_curStation.m_iTemporaryDirection = INT_DIRECTION_NORTH;
        
        [self getTrainStatus];
        return;
    }
    
    if ([oStation.m_strNorthDirection length] < 1) {
        
        [self makeBusy];
        m_curStation = oStation;
        m_curStation.m_iTemporaryDirection = INT_DIRECTION_SOUTH;
        
        [self getTrainStatus];
        return;
    }
    
    [self showDirection2View:oStation:0.0];
    
    
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    m_ctrlLblWalkingDistance.text = @"";
    
    [self clearStatusValues];
    
    m_ctrlViewHide.hidden = YES;
    m_viewDim.hidden = YES;
    m_ctrlActivity.hidden = YES;
    [m_ctrlActivity startAnimating];
    m_ctrlActivity.backgroundColor = [UIColor clearColor];
    
    [NSTimer scheduledTimerWithTimeInterval:INT_UPDATE_STATUS_TIMER_DELAY target:self selector:@selector(timerUpdationCalled) userInfo:nil repeats:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:INT_UPDATE_WALK_DIST_TIMER_DELAY target:self selector:@selector(timerWalkDistanceCalled) userInfo:nil repeats:YES];
    
    
    m_curStation = nil;
    
    m_arrNextTrains = [[NSMutableArray alloc] init];
    m_iCurrentTrainPos = -1;
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleHideLeftMenuView:)	 name:@"EVENT_HIDE_LEFT_MENU_VIEW"
												object:nil];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleLeftMenuSelected:)	 name:@"EVENT_LEFT_MENU_SELECTED"
												object:nil];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleOneAllStationSelected:)	 name:@"EVENT_ONE_ALL_STATION_SELECTED"
												object:nil];

    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleDirection2Selected:)	 name:@"EVENT_DIRECTION_2_SELECTED"
												object:nil];
    
    
    m_Direction2View = [self getDirection2View];
    [m_Direction2View initCtrl];
    m_Direction2View.hidden = YES;
    m_Direction2View.alpha = 0.0;
    [self.view addSubview:m_Direction2View];
    m_viewDim.backgroundColor = [UIColor blackColor];
    m_viewDim.hidden = YES;
    m_viewDim.alpha = 0.0;

    
    

    m_LeftMenuView = [self getLeftMenuView];
    [m_LeftMenuView initControl];
    m_LeftMenuView.frame = CGRectMake(0-INT_LEFT_NAV_MOVE_DISTANCE, 0, m_LeftMenuView.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:m_LeftMenuView];
    m_LeftMenuView.hidden = YES;

  
    
    [self checkAndDisplayConfigScreens:NO];
    
    [self setStatusValues];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
