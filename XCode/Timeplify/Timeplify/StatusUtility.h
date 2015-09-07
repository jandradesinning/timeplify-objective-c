//
//  StatusUtility.h
//  Timeplify
//
//  Created by Anil on 10/01/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ST_Station;

@interface StatusUtility : NSObject
{
    
}
-(UIColor*) getServiceStatusColor:(NSDictionary*)IN_Dict;
-(NSString*) getServiceStatusText:(NSDictionary*)IN_Dict;
-(NSMutableAttributedString*) getServiceStatusFormattedText:(NSString*)IN_strStatus :(UIColor*)IN_Color :(BOOL)IN_bRealTime;
-(NSString*) getServiceStatusfromDefault:(NSDictionary*)IN_Dict;
-(void) storeServiceStatusInDefault:(NSDictionary*)IN_Dict;
-(BOOL) isServiceStatusStoredInDefault;

-(ST_Station*) getEarlyStationRouteForGPSNearest:(NSMutableArray*)IN_arrNextTrains :(ST_Station*)IN_curStation :(NSMutableArray*)IN_arrGPSStations;

-(NSMutableArray*) getFormattedStatusResult:(NSDictionary*)IN_Dict :(BOOL) IN_bLocalData :(ST_Station*)IN_curStation;
-(NSString*) getTimeRemaining:(NSDictionary*)IN_Dict;
-(NSString*) getNextTimeRemaining:(NSMutableArray*)IN_ArrRecs :(ST_Station*)IN_curStation;
-(NSString*) getWalkingDistance:(NSDictionary*)IN_Dict;
-(NSString*) getFormattedSeconds:(int) IN_iSecs;

-(NSString*) getUnitOnlyFromFormattedSecs:(NSString*)IN_strTxt;
-(NSString*) getTimeOnlyFromFormattedSecs:(NSString*)IN_strTxt;

-(NSMutableDictionary*) getLocalDBScheduledData:(ST_Station*) IN_Station;

-(int) getTimeRemainingInSecs:(NSDictionary*)IN_Dict;
-(int) getWalkingDistanceInSecs:(NSDictionary*)IN_Dict;
-(BOOL) doesRouteHaveLive:(NSString*)IN_strRoute;

-(NSMutableDictionary*) getCurrentDisplayingDict:(NSMutableArray*)IN_arrRecs :(ST_Station*)IN_curStation;
-(NSMutableDictionary*) getNextDisplayingDict:(NSMutableArray*)IN_arrRecs :(ST_Station*)IN_curStation;
@end