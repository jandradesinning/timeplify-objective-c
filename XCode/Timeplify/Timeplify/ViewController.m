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

#import "PullDownRefreshScrollView.h"

#import "SeeAllTrainsViewController.h"
#import "DummyLeftRightView.h"
#import "PullRefreshView.h"
#import "Reachability.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize m_VCFlipParent;
@synthesize m_bDummyFlip;

@synthesize m_ctrlLblNoInternet;
@synthesize m_ctrlBtnLeftArrow;
@synthesize m_ctrlBtnRightArrow;
@synthesize m_ctrlBtnSwitchDirection;
@synthesize m_ctrlLblService;
@synthesize m_ctrlLblDataType;
@synthesize m_ctrlLblMainTimeValue;
@synthesize m_ctrlLblMainTimeUnit;
@synthesize m_ctrlLblNextTime;
@synthesize m_ctrlLblWalkingDistance;
@synthesize m_ctrlLblStation;
@synthesize m_ctrlLblDirection;
@synthesize m_ctrlImgViewTrain;



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



#pragma mark DataTypeBlink

- (void)animationToDataTypeBlinkStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
    m_ctrlLblDataType.alpha = 1.0;
}

// This is to manage the blinking for when Live Data is available
-(void) doDataTypeBlink
{
    if (m_bDataTypeBlink == NO) {
        m_ctrlLblDataType.alpha = 1.0;
        return;
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:1.7]; // changed from 0.8 to 1.7
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToDataTypeBlinkStopped:finished:context:)];
    m_ctrlLblDataType.alpha = 0.0;
    [UIView commitAnimations];
}

#pragma mark JustLeftActions

- (void)animationToGrayZeroStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
    m_ctrlLblMainTimeValue.alpha = 1.0;
}

-(void) justLeftTimerCalled
{
    [self doDataTypeBlink];
    
    m_iJustLeftCalls++;
    
    m_ctrlLblMainTimeValue.text = @"0";
    
    
    m_ctrlLblMainTimeValue.alpha = 1.0;
    
    if (m_iJustLeftCalls > INT_ZERO_BLINK_TIMES) {
        m_ctrlLblMainTimeValue.text = @"Just Left";
    }
    else
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:1.7]; // changed from 0.8 to 1.2
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationToGrayZeroStopped:finished:context:)];
        m_ctrlLblMainTimeValue.alpha = 0.0;
        [UIView commitAnimations];
    }

    if (m_iJustLeftCalls > (INT_ZERO_BLINK_TIMES+INT_JUST_LEFT_BLINK_TIMES)) {
        m_ctrlLblMainTimeValue.alpha = 1.0;
        [m_timerJustLeft invalidate];
         m_timerJustLeft = nil;
        [self removeLeftTrains];
        [self setStatusValues];
        
        
        if ([m_arrNextTrains count] < 1) {
            [self timerServerReCallCalled];
        }
    }
    
    
}

-(void) doJustLeftActions
{
    
    if (m_timerJustLeft != nil) {
        [m_timerJustLeft invalidate];
        m_timerJustLeft = nil;
    }
    
    m_iJustLeftCalls = 1;
    m_timerJustLeft = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(justLeftTimerCalled)
                                                    userInfo:nil
                                                     repeats:YES];
    
}



#pragma mark VibrateAlert

-(void) vibrateTimerCalled
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    m_iVibrateCalls++;
    
    if (m_iVibrateCalls > INT_VIBRATE_TIMES) {
        if (m_timerVibrate != nil) {
            [m_timerVibrate invalidate];
            m_timerVibrate = nil;
        }
    }
}

-(void) doVibrateAlert
{
    
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

// This function is called every second
-(void) timerUpdationCalled
{
    if (m_timerJustLeft != nil) { // if the screen shows TimeJustLeft indicator, then update the NextTime on the screen
        
        StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
        NSString* strNextTime = [oStatusUtil getNextTimeRemaining:m_arrNextTrains :m_curStation];
        m_ctrlLblNextTime.text = strNextTime;
        
        return;
    }
    
    
    [self removeOtherRoutesLeftTrains];
    
    
    [self setStatusValues];

}


-(void) timerServerReCallCalled
{
    if (m_timerJustLeft != nil) {
        return;
    }
    
    
    if (m_bRunningMode == YES) {
        [self getTrainStatusFromServer];
    }
    
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
    m_curStation.m_iTemporaryDirection = m_curStation.m_iTemporaryDirection;
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
    
    int iDirection = -1;
    if (m_curStation != nil) {
        iDirection = m_curStation.m_iTemporaryDirection;
    }
    
    [m_LeftMenuView setValues:iDirection];
    
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

-(void) showSeeAllTrains
{
    SeeAllTrainsViewController* viewController = [[SeeAllTrainsViewController alloc] initWithNibName:@"SeeAllTrainsViewController" bundle:nil];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

-(void)handleHideLeftMenuView:(NSNotification *)pNotification
{
    [self hideLeftMenu];
}


-(void)handleLeftMenuSelected:(NSNotification *)pNotification
{
    NSIndexPath* oInd = [pNotification object];
    
    /*
    if (oInd.row == 0) {
                
        [self showSeeAllTrains];
    }
    
    if (oInd.row == 1) {
        [self showFavorites];
    }
     */
    
    if (oInd.row == 0) {
        [self showAbout];
    }
    
    if (oInd.row == 1) {
        [Utility rateThisApp];
    }
    
    [self hideLeftMenu];
}


#pragma mark DummyLeftRightView


-(DummyLeftRightView*) getDummyLeftRightView
{
    DummyLeftRightView* oView = nil;
    
    NSArray *topLevelObjects;
    
    if ([Utility isDeviceiPhone5]) {
        topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"DummyLeftRightView_5" owner:self options:nil];
        
    }
    else
    {
        topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"DummyLeftRightView" owner:self options:nil];
        
    }
    
	for (id currentObject in topLevelObjects){
		if ([currentObject isKindOfClass:[DummyLeftRightView class]]){
			oView =  (DummyLeftRightView *) currentObject;
			break;
		}
	}
    return oView;
}

-(void) doScrollLeftRight:(ST_Station*)IN_Left :(ST_Station*)IN_Right
{
    [m_DummyLeftView removeFromSuperview];
    [m_DummyRightView removeFromSuperview];
    
    double dbScreenWd = self.view.frame.size.width;
    double dbMainViewPos = 0;
    double dbRightViewPos = 0;
    double dbTotalWidth = 0;
    double dbOffsetX = 0;
    double dbX = m_ctrlLblDirection.frame.origin.x;
    if ((IN_Left ==nil)&&(IN_Right == nil)) {
        if (dbX < 100) {
            dbMainViewPos = 0;
        }
        else
        {
            dbMainViewPos = -dbScreenWd;
        }
        
        dbTotalWidth =dbScreenWd;
        dbOffsetX = 0;
    }
    
    
    if ((IN_Left !=nil)&&(IN_Right == nil)) {
        if (dbX < 100) {
            dbMainViewPos = dbScreenWd;
        }
        else
        {
            dbMainViewPos = 0;
        }
        
        dbTotalWidth =2*dbScreenWd;
        dbOffsetX = dbScreenWd;
    }
    
    if ((IN_Left ==nil)&&(IN_Right != nil)) {
        if (dbX < 100) {
            dbMainViewPos = 0;
        }
        else
        {
            dbMainViewPos = -dbScreenWd;
        }
        dbRightViewPos = dbScreenWd;
        dbTotalWidth =2*dbScreenWd;
        dbOffsetX = 0;
    }
    
    if ((IN_Left !=nil)&&(IN_Right != nil)) {
        if (dbX < 100) {
            dbMainViewPos = dbScreenWd;
        }
        else
        {
            dbMainViewPos = 0;
        }
        dbRightViewPos = 2*dbScreenWd;
        dbTotalWidth =3*dbScreenWd;
        dbOffsetX = dbScreenWd;
    }

    
    
    
    
    for (int i= 0; i < [m_ctrlPullDownScrollView.subviews count]; i++) {
        UIView* oView = [m_ctrlPullDownScrollView.subviews objectAtIndex:i];
        if (oView.tag != 33) {
            continue;
        }
        
        CGRect oRct = oView.frame;
        oRct.origin.x+=dbMainViewPos;
        oView.frame = oRct;
    }
    
    
    if (IN_Left != nil) {
        CGRect oRct = m_DummyLeftView.frame;
        oRct.origin.x=0;
        m_DummyLeftView.frame = oRct;
        
        m_DummyLeftView.m_ctrlLblStation.text = IN_Left.m_strStationName;
        
        [m_ctrlPullDownScrollView addSubview:m_DummyLeftView];
    }
    
    if (IN_Right != nil) {
        CGRect oRct = m_DummyRightView.frame;
        oRct.origin.x=dbRightViewPos;
        m_DummyRightView.frame = oRct;
        
        m_DummyRightView.m_ctrlLblStation.text = IN_Right.m_strStationName;
        
        [m_ctrlPullDownScrollView addSubview:m_DummyRightView];
    }
    m_ctrlPullDownScrollView.contentSize = CGSizeMake(dbTotalWidth, self.view.frame.size.height+1);
    
    
    CGPoint ptOff = CGPointMake(dbOffsetX, 0);
    m_dbOffSetPrevious = dbOffsetX;
    m_ctrlPullDownScrollView.contentOffset = ptOff;
    
    CGRect oRect = m_viewDim.frame;
    oRect.origin.x = 0;
    oRect.size.width = dbTotalWidth;
    m_viewDim.frame = oRect;
    
    
    oRect = m_ctrlPullDownScrollView.refreshView.frame;
    oRect.origin.x = dbOffsetX;
    m_ctrlPullDownScrollView.refreshView.frame = oRect;
    
}


-(void) updateScrollLeftRight
{
    
    if (m_curStation == nil) {
        [self doScrollLeftRight:nil:nil];
        return;
    }
    
    NearestStation* oNear = [[NearestStation alloc] init];
    ST_Station* oStation1 = nil;
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        oStation1 = [oNear getPrevStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    else
    {
        oStation1 = [oNear getNextStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    
    
    ST_Station* oStation2 = nil;
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        
        oStation2 = [oNear getNextStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    else
    {
        oStation2 = [oNear getPrevStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
       
    
    [self doScrollLeftRight:oStation1:oStation2];
    
    
}


#pragma mark Get Status


-(void) updateButtonStyles
{
    m_ctrlBtnLeftArrow.enabled = NO;
    m_ctrlBtnRightArrow.enabled = NO;
    
    
    if (m_curStation == nil) {
        m_ctrlBtnSwitchDirection.enabled = NO;
        return;
    }
    
    NearestStation* oNear = [[NearestStation alloc] init];
    
    ST_Station* oStation1 = nil;
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        oStation1 = [oNear getPrevStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    else
    {
        oStation1 = [oNear getNextStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    if (oStation1 != nil) {
        m_ctrlBtnLeftArrow.enabled = YES;
    }
    
    
    
    
    ST_Station* oStation2 = nil;
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        
        oStation2 = [oNear getNextStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    else
    {
        oStation2 = [oNear getPrevStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    
    if (oStation2 != nil) {
        m_ctrlBtnRightArrow.enabled = YES;
    }
        
    
    ST_Station* oOrderedNextStation = [oNear getNextStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    ST_Station* oOrderedPrevStation = [oNear getPrevStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    

    
    m_ctrlBtnSwitchDirection.enabled = NO;
    
    if  ((m_curStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) &&
         (oOrderedNextStation != nil))
    {
        m_ctrlBtnSwitchDirection.enabled = YES;
    }
    
    if  ((m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) &&
         (oOrderedPrevStation != nil))
    {
        m_ctrlBtnSwitchDirection.enabled = YES;
    }
    
}



-(void) clearStatusValues
{
    m_ctrlLblLastStation.text = @"";
    m_ctrlLblService.text = @"";
    m_ctrlLblDataType.text = @"";
    m_ctrlLblMainTimeValue.text = @"0";
    m_ctrlLblMainTimeUnit.text = @"";
    m_ctrlLblNextTime.text = @"";
    m_ctrlLblStation.text = @"";
    m_ctrlLblDirection.text = @"";
    m_ctrlImgViewTrain.image = nil;
    m_bDataTypeBlink = NO;
    m_ctrlLblWalkingDistance.text = @"";
}

-(void) setServiceStatus:(NSMutableDictionary*)IN_Dict
{
    
    StatusUtility* oSUtil = [[StatusUtility alloc] init];
    NSString* strTxt = [oSUtil getServiceStatusText:IN_Dict];
    
    m_ctrlLblService.text = strTxt;
    
    UIColor* oClr = [oSUtil getServiceStatusColor:IN_Dict];

    m_ctrlLblService.textColor = oClr;
}

// This code runs every second and this code removes the first time on the left menu when it expires
-(void) removeOtherRoutesLeftTrains
{
    
    if ([m_arrNextTrains count] < 1)
    {
        return;
    }
    
    NSMutableDictionary* oDict = [m_arrNextTrains objectAtIndex:0];
    
    NSString* strRouteId = [oDict objectForKey:@"routeId"];
    
    if ([strRouteId isEqualToString:m_curStation.m_strRouteId]) {
        return;
    }
    
    
    StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
    NSString* strTime = [oStatusUtil getTimeRemaining:oDict];
    if ([strTime length] < 1) {
        [m_arrNextTrains removeObjectAtIndex:0];
        [self removeOtherRoutesLeftTrains];
        return;
    }
    
}

-(void) removeLeftTrains
{
    
    if ([m_arrNextTrains count] < 1)
    {
        return;
    }
    
    NSMutableDictionary* oDict = [m_arrNextTrains objectAtIndex:0];
    
    StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
    NSString* strTime = [oStatusUtil getTimeRemaining:oDict];
    
    if ([strTime length] < 1) {
        [m_arrNextTrains removeObjectAtIndex:0];
        [self removeLeftTrains];
        return;
    }

}


-(void) setStatusValues
{
    
    [self doDataTypeBlink];
    
    if ([m_arrNextTrains count] < 1) {
        return;
    }
    
    StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
    
    NSMutableDictionary* oDict = [oStatusUtil getCurrentDisplayingDict:m_arrNextTrains :m_curStation];
    
    if (oDict == nil) {
        return;
    }
    
    NSString* strRoute = [oDict objectForKey:@"routeId"];
    if (strRoute == nil) {
        return;
    }
    
    NSString* strNormalImage = [NSString stringWithFormat:@"vehicle-logo-%@.png", strRoute];
    strNormalImage = [strNormalImage lowercaseString];
    
    
    // Question: Is it necessary to set the image and station name every second for the currently select station?
    
    m_ctrlImgViewTrain.image = [UIImage imageNamed:strNormalImage];
    m_ctrlLblStation.text = m_curStation.m_strStationName;
    
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        m_ctrlLblDirection.text = m_curStation.m_strNorthDirection;
    }
    
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        m_ctrlLblDirection.text = m_curStation.m_strSouthDirection;
    }
    
    // This is to tell whether the data is real time or scheduled and set the m_bDataTypeBlink accordingly
    
    NSString* strReal = [oDict objectForKey:@"REAL_TIME"];
    if ([strReal isEqualToString:@"YES"]) {
        m_ctrlLblDataType.text = @"Realtime Data";
        m_bDataTypeBlink = YES;
    }
    else
    {
        m_ctrlLblDataType.text = @"Scheduled Data";
        m_bDataTypeBlink = NO;
    }
    
    
    // This is to retrieve the status label (Delay, Good Service, etc) and also the status color
    [self setServiceStatus:oDict];
    
    m_ctrlLblLastStation.text = [oDict objectForKey:@"LAST_STATION"];
    
    // LEFT
    m_DummyLeftView.m_ctrlImgViewTrain.image = m_ctrlImgViewTrain.image;
    m_DummyLeftView.m_ctrlLblLastStation.text = m_ctrlLblLastStation.text;
    m_DummyLeftView.m_ctrlLblDirection.text = m_ctrlLblDirection.text;
    
    // RIGHT
    m_DummyRightView.m_ctrlImgViewTrain.image = m_ctrlImgViewTrain.image;
    m_DummyRightView.m_ctrlLblLastStation.text = m_ctrlLblLastStation.text;
    m_DummyRightView.m_ctrlLblDirection.text = m_ctrlLblDirection.text;
    

    
    
    int iTimeRemaining = [oStatusUtil getTimeRemainingInSecs:oDict];
    
    // Vibrate logic to indicate to the user he is cutting it close
    
    if (iTimeRemaining < m_iWalkingDistance) {
        if (m_iVibrateCalls < 1) {
            
            if (m_bRemainingWasUp == YES) {
                [self doVibrateAlert];
            }
            
        }
    }
    else
    {
        if (m_iWalkingDistance > 0) {
            m_bRemainingWasUp = YES;
        }
        
    }
    
    
    NSString* strTime = [oStatusUtil getTimeRemaining:oDict];
    NSString* strTimeOnly = [oStatusUtil getTimeOnlyFromFormattedSecs:strTime];
    double dbTimeLeft = [strTimeOnly doubleValue];
    if (dbTimeLeft < 1) {
        m_ctrlLblMainTimeValue.text = @"0";
        [self doJustLeftActions];
        
        return;
    }
    
    
    
    NSString* strUnit = [oStatusUtil getUnitOnlyFromFormattedSecs:strTime];
    
    
    
    m_ctrlLblMainTimeValue.text = strTimeOnly;
    m_ctrlLblMainTimeUnit.text = strUnit;
    
    
    NSString* strNextTime = [oStatusUtil getNextTimeRemaining:m_arrNextTrains :m_curStation];
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




-(int)parseStatusServerResponse:(NSDictionary*)IN_Dict :(BOOL) IN_bUsingLocal
{
    
    
    if (IN_bUsingLocal == YES) {
        [self performSelector:@selector(getTrainStatusFromLocalDB) withObject:nil afterDelay:0.0];
        return 0;
    }
    
    
    
    m_bRemainingWasUp = NO;
    m_iWalkingDistance = 0;
    
    

    if (IN_Dict == nil) {
        [self displayError:@"Invalid response from server"];
        return 1;
    }

    NSDictionary* oDictData = [IN_Dict objectForKey:@"data"];
    if (oDictData == nil) {
        [self displayError:@"Invalid response from server"];
        return 1;
    }

    
    
    NSDictionary* oDict = oDictData;
    
    StatusUtility* oUtil = [[StatusUtility alloc]   init];
    
    if (!([oDict isKindOfClass:[NSDictionary class]])) {
        [self displayError:@"Invalid response from server"];
        return 1;
    }
   
    [oUtil storeServiceStatusInDefault:oDict];
    
    
    
    NSNumber* oNumStatus = [IN_Dict objectForKey:@"status"];
    if (oNumStatus != nil) {
        if ([oNumStatus intValue] == 1) {
            [self performSelector:@selector(getTrainStatusFromLocalDB) withObject:nil afterDelay:0.0];
            return 0;
        }
        
    }

    
    
    m_arrNextTrains = [oUtil getFormattedStatusResult:oDict:IN_bUsingLocal:m_curStation];
    
   
    if ([m_arrNextTrains count] > 0) {
        m_iVibrateCalls = 0;
    }
    
    [self setStatusValues];
    
    return 1;
}


-(void) getTrainStatusFromLocalDB
{
    ST_Station* oStation = m_curStation;
    NSString* strDirection = @"";
    if (oStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        strDirection = @"N";
    }
    if (oStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        strDirection = @"S";
    }
       
    
    m_bRemainingWasUp = NO;
    m_iWalkingDistance = 0;
    
    
    
    StatusUtility* oUtil = [[StatusUtility alloc]   init];
    
    NSMutableDictionary* oDict = [oUtil getLocalDBScheduledData:oStation];
    
    
    m_arrNextTrains = [oUtil getFormattedStatusResult:oDict:YES:m_curStation];
    
    
    if ([m_arrNextTrains count] > 0) {
        m_iVibrateCalls = 0;
    }
    
    [self setStatusValues];

    
    
    [self makeReady];
}


-(void)getTrainStatusFromServer
{
   
    
    
    ST_Station* oStation = m_curStation;
    
    
    NSString* strDirection = @"";
    if (oStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        strDirection = @"N";
    }
    
    if (oStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        strDirection = @"S";
    }
    
    
    NSMutableDictionary* oDictParam= [[NSMutableDictionary alloc] init];
    [oDictParam setObject:@"1.0" forKey:@"appVersion"];
    [oDictParam setObject:oStation.m_strStationId forKey:@"station"];
    [oDictParam setObject:oStation.m_strRouteId forKey:@"route"];
    [oDictParam setObject:strDirection forKey:@"direction"];
    [oDictParam setObject:[NSNumber numberWithBool:NO] forKey:@"fetchScheduledData"];
    
    

    
    [PFCloud callFunctionInBackground:@"getStatus" withParameters:oDictParam
                                block:^(id result, NSError *error)
     {
         
         int iServerOk = 1;

         if (error) {
             
             if ([error code] == 100) {
                 //[self displayError:@"We’re unable to connect to Timeplify Servers, please check your connection and try again to receive live updates."];
                 
                 iServerOk = [self parseStatusServerResponse: nil :YES];
             }
             else
             {
                 if (m_bRunningMode == NO) {
                     [self displayError:[error localizedDescription]];
                 }
                 
             }
             
         }
         else
         {
             iServerOk = [self parseStatusServerResponse: result :NO];
             m_bRunningMode = YES;
             
         }
         
         if (iServerOk == 1) {
             [self makeReady];
         }
         
         NSLog(@"Over");
         
     }];
    
    
    NSLog(@"Called");
}



-(void) getTrainStatus
{
    
    if (m_timerVibrate != nil) {
        [m_timerVibrate invalidate];
        m_timerVibrate = nil;
    }

    if (m_timerJustLeft != nil) {
        [m_timerJustLeft invalidate];
        m_timerJustLeft = nil;
        m_ctrlLblMainTimeValue.alpha = 1.0;
    }

    m_ctrlLblMainTimeValue.hidden = NO;
    
    
    
    m_bRunningMode = NO;
    [self clearStatusValues];
    
    [m_arrNextTrains removeAllObjects];
    
    m_ctrlLblWalkingDistance.text = @"";
    [self getWalkingDistance];
    
    StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
    BOOL bHasLive = [oStatusUtil doesRouteHaveLive:m_curStation.m_strRouteId];
    BOOL bStatusStored = [oStatusUtil isServiceStatusStoredInDefault];
    if ((bHasLive == YES)||(bStatusStored == NO)) {
        [self getTrainStatusFromServer];
    }
    else
    {
        [self performSelector:@selector(getTrainStatusFromLocalDB) withObject:nil afterDelay:0.0];
    }
        
    
    [self updateButtonStyles];
    [self updateScrollLeftRight];
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

}






-(IBAction) btnMenuClicked:(id)sender
{
    [self showLeftMenu];
}

-(IBAction) btnSubwayClicked:(id)sender
{
    [self showSeeAllTrains];
}

-(IBAction) btnFavoriteClicked:(id)sender
{
    [self showFavorites];
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
    
    if (m_curStation != nil) {
        [self makeBusy];
        [self getTrainStatus];
        return;
    }
    

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
    
    
    
    
    
    
    
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        
        ViewController* oVC2 = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
        oVC2.m_bDummyFlip = YES;
        oVC2.m_VCFlipParent = nil;
        oVC2.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:oVC2 animated:YES completion:^(){
            
            dispatch_after(0, dispatch_get_main_queue(), ^{
                
                [oVC2 dismissViewControllerAnimated:NO completion:nil];
                
                [self makeBusy];
                [self getTrainStatus];
                
            });
            
        }];
        
    }
    else
    {
        
        ViewController* oVC2 = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
        oVC2.m_bDummyFlip = YES;
        oVC2.m_VCFlipParent = self;
        oVC2.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:oVC2 animated:NO completion:^(){
            
            dispatch_after(0, dispatch_get_main_queue(), ^{
                
                [self makeBusy];
                [self getTrainStatus];
                oVC2.m_VCFlipParent = nil;
                [oVC2 dismissViewControllerAnimated:YES completion:^(){
                    
                    
                }];
                
                
            });
            
            
        }];
        
    }

    
    
    
    
}

-(void) goToLeftScreen
{
    if (m_curStation == nil) {
        return;
    }
    
    NearestStation* oNear = [[NearestStation alloc] init];
    
    ST_Station* oStation = nil;
    
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        oStation = [oNear getPrevStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    else
    {
        oStation = [oNear getNextStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    
    
    if (oStation == nil) {
        return;
    }
    
    [self makeBusy];
    
    oStation.m_iTemporaryDirection = m_curStation.m_iTemporaryDirection;
    m_curStation = oStation;
    [self getTrainStatus];
    

}

-(void) goToRightScreen
{
    if (m_curStation == nil) {
        return;
    }
    
    NearestStation* oNear = [[NearestStation alloc] init];
    
    ST_Station* oStation = nil;
    
    if (m_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
        
        oStation = [oNear getNextStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }
    else
    {
        oStation = [oNear getPrevStationofStation:m_curStation :m_curStation.m_iTemporaryDirection];
    }

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

/*
-(void) arrangeHideView
{
    CGRect oRct = m_ctrlViewHide.frame;
    oRct.size.height = self.view.frame.size.height - oRct.origin.y;
    oRct.size.width = self.view.frame.size.width;
    m_ctrlViewHide.frame = oRct;
    
}
*/

-(void) viewWillAppear:(BOOL)animated
{
    
    m_ctrlPullDownScrollView.contentSize = CGSizeMake(self.view.frame.size.width+1,self.view.frame.size.height+1);
    
    m_viewDim.frame = self.view.frame;
    m_Direction2View.frame = self.view.frame;
    
    CGRect oRct = m_LeftMenuView.frame;
    oRct.size.height = self.view.frame.size.height;
    m_LeftMenuView.frame = oRct;
    
//    [self arrangeHideView];
    
    [self updateScrollLeftRight];
    
    [self setInternetStatus];
}



-(void)handleFavStationSelected:(NSNotification *)pNotification
{
    ST_Station* oStation = [pNotification object];
    
    NSLog(@"handleFavStationSelected '%@'", oStation.m_strStationName);
    
    if ((oStation.m_iSelectedDirection == INT_DIRECTION_NORTH)||
        (oStation.m_iSelectedDirection == INT_DIRECTION_SOUTH)){
        
        [self makeBusy];
        m_curStation = oStation;
        oStation.m_iTemporaryDirection = oStation.m_iSelectedDirection;
        [self getTrainStatus];
        return;

    }
    
    [self showDirection2View:oStation:0.0];
    
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



-(void)handleAllSetInitially:(NSNotification *)pNotification
{    
    NSArray* oArr = (NSArray*) [Utility getObjectFromDefault:STR_KEY_FAV_TRAINS];
    if (oArr == nil) {
        return;
    }
    
    if (m_bFirstCallMade == YES) {
        return;
    }
    
    m_bFirstCallMade = YES;
    
    [self btnGPSClicked:0];

}


-(void)handleSignificantGPSChange:(NSNotification *)pNotification
{
    [self getWalkingDistance];
    
}

-(void)handlePulledToRefresh:(NSNotification *)pNotification
{

    [self btnGPSClicked:0];
    
}

-(void) doMainViewSwipedAction:(NSString*)IN_strTxt
{
    
    if ([IN_strTxt isEqualToString:@"LEFT"]) {
        [self goToLeftScreen];
    }
    else
    {
        [self goToRightScreen];
    }

    
}

-(void)handleSwipedMainView:(NSNotification *)pNotification
{
    NSLog(@"handleSwipedMainView");

        
    NSString* strDir = (NSString*)[pNotification object];
    
    [self performSelector:@selector(doMainViewSwipedAction:) withObject:strDir afterDelay:0.0];
    
}

-(void)handleDecelaratedMainView:(NSNotification *)pNotification
{
    
    NSLog(@"handleDecelaratedMainView");
    
    double dbNewX = m_ctrlPullDownScrollView.contentOffset.x;
    
    if (dbNewX < (m_dbOffSetPrevious - 100)) {
        [self goToLeftScreen];
        return;
    }

    if (dbNewX > (m_dbOffSetPrevious + 100)) {
        [self goToRightScreen];
        return;
    }
}

-(void) setInternetStatus
{
    AppDelegate* appDel = (AppDelegate*)[[UIApplication sharedApplication] delegate];
   
    if (appDel.m_Reachability.currentReachabilityStatus ==NotReachable) {
        m_ctrlLblNoInternet.hidden = NO;
    }
    else
    {
        m_ctrlLblNoInternet.hidden = YES;
    }

}

-(void)handleReachabilityChanged:(NSNotification *)pNotification
{
    NSLog(@"handleReachabilityChanged");
    [self setInternetStatus];
}

-(void) setFlipControllerValues
{
    if (m_VCFlipParent == nil) {
        return;
    }
    
    
    m_ctrlBtnLeftArrow.enabled = m_VCFlipParent.m_ctrlBtnLeftArrow.enabled;
    m_ctrlBtnRightArrow.enabled = m_VCFlipParent.m_ctrlBtnRightArrow.enabled;
    m_ctrlBtnSwitchDirection.enabled = m_VCFlipParent.m_ctrlBtnSwitchDirection.enabled;
    
    m_ctrlLblService.text = m_VCFlipParent.m_ctrlLblService.text;
    m_ctrlLblDataType.text = m_VCFlipParent.m_ctrlLblDataType.text;
    m_ctrlLblMainTimeValue.text = m_VCFlipParent.m_ctrlLblMainTimeValue.text;
    m_ctrlLblMainTimeUnit.text = m_VCFlipParent.m_ctrlLblMainTimeUnit.text;
    m_ctrlLblNextTime.text = m_VCFlipParent.m_ctrlLblNextTime.text;
    m_ctrlLblWalkingDistance.text = m_VCFlipParent.m_ctrlLblWalkingDistance.text;
    m_ctrlLblStation.text = m_VCFlipParent.m_ctrlLblStation.text;
    m_ctrlLblDirection.text = m_VCFlipParent.m_ctrlLblDirection.text;
    
    m_ctrlLblNoInternet.hidden = m_VCFlipParent.m_ctrlLblNoInternet.hidden;
    
    
    m_ctrlImgViewTrain.image = m_VCFlipParent.m_ctrlImgViewTrain.image;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    
    self.automaticallyAdjustsScrollViewInsets = NO; //The default value of this property is YES, which allows the view controller to adjust its scroll view insets in response to the screen areas consumed by the status bar, navigation bar, and toolbar or tab bar. Set to NO if you want to manage scroll view inset adjustments yourself, such as when there is more than one scroll view in the view hierarchy.

    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Question: why do we send the message of removeObserver when the view loads for the first time?
    
    
    m_bFirstCallMade = NO;
    // Question: why is this set in handleAllSetInitially?
    
    m_ctrlLblNoInternet.hidden = YES;
    // This is the object that controlls the Internet status banner and it must be hidden when the view loads
    
    // m_ctrlLblWalkingDistance.text = @""
    // m_ctrlLblService.text = @"";

    // removed the two lines above before this is part of clearStatusValues
    
    [self clearStatusValues];
    // clearStatusValues allows to clear all values for each of the fields on the GUI
    
    
    m_ctrlViewHide.hidden = YES;
    // Question: what does m_ctrlViewHide do? Can it be safely removed?
    
    m_viewDim.hidden = YES;
    // This is a nice gray layer that appears while the view is in make busy. It needs to be hidden on first launch.
    
    m_ctrlActivity.hidden = YES;
    // This is the activity monitor, it has to be hidden when the view loads
    
    [m_ctrlActivity startAnimating];
    // Question: Is this really needed here? Given that we have hidden the ctrlActivity before calling this?
    
    m_ctrlActivity.backgroundColor = [UIColor clearColor];
    // Makes sense to to set background color to clear so that it's not shown, but we need to know why we need to start the animation here if it's hidden before the animation starts.
    
    
    [m_ctrlPullDownScrollView initPushLoadingView];
    // All this does is initialize the PullRefresh code, no actual implementation here
    
    
    if (m_bDummyFlip == NO)
    {  // Question: what does m_bDummyFlip exactly do? I can see it gets set to NO at application launch on the delegate
        
        [NSTimer scheduledTimerWithTimeInterval:INT_UPDATE_STATUS_TIMER_DELAY target:self selector:@selector(timerUpdationCalled) userInfo:nil repeats:YES];
        
        [NSTimer scheduledTimerWithTimeInterval:INT_UPDATE_SERVER_RECALL_TIMER_DELAY target:self selector:@selector(timerServerReCallCalled) userInfo:nil repeats:YES];
        
        
        m_DummyLeftView = [self getDummyLeftRightView];
        m_DummyLeftView.m_bLeft = YES;
        
        m_DummyRightView = [self getDummyLeftRightView];
        m_DummyRightView.m_bLeft = NO;

    }
    
    
    
    m_curStation = nil;
    
    m_arrNextTrains = [[NSMutableArray alloc] init];
    
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleSignificantGPSChange:)	 name:@"EVENT_SIGNIFICANT_GPS_CHANGE"
												object:nil];
 
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleHideLeftMenuView:)	 name:@"EVENT_HIDE_LEFT_MENU_VIEW"
												object:nil];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleLeftMenuSelected:)	 name:@"EVENT_LEFT_MENU_SELECTED"
												object:nil];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleOneAllStationSelected:)	 name:@"EVENT_ONE_ALL_STATION_SELECTED"
												object:nil];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleFavStationSelected:)	 name:@"EVENT_FAV_STATION_SELECTED"
												object:nil];
    
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleDirection2Selected:)	 name:@"EVENT_DIRECTION_2_SELECTED"
												object:nil];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleAllSetInitially:)	 name:@"EVENT_ALL_SET_INITIALLY"
												object:nil];
    
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handlePulledToRefresh:)	 name:@"EVENT_PULLED_TO_REFRESH"
												object:nil];
    
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleSwipedMainView:)	 name:@"EVENT_SWIPED_MAIN_VIEW"
												object:nil];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleDecelaratedMainView:)	 name:@"EVENT_MAIN_VIEW_DECELARATED"
												object:nil];

    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleReachabilityChanged:)	 name:@"EVENT_REACHABILITY_CHANGED"
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
    
    [self updateButtonStyles];
    
    if (m_VCFlipParent != nil) {
        [self setFlipControllerValues];
    }
    
    m_ctrlPullDownScrollView.pagingEnabled = YES;
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) dealloc
{
    NSLog(@"VC DEALLOC");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
