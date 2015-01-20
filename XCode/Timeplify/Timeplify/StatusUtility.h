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
-(NSMutableArray*) getFormattedStatusResult:(NSDictionary*)IN_Dict :(BOOL) IN_bLocalData;
-(NSString*) getTimeRemaining:(NSDictionary*)IN_Dict;
-(NSString*) getNextTimeRemaining:(NSMutableArray*)IN_ArrRecs :(int) IN_iCurPos;
-(NSString*) getWalkingDistance:(NSDictionary*)IN_Dict;
-(NSString*) getFormattedSeconds:(int) IN_iSecs;

-(NSString*) getUnitOnlyFromFormattedSecs:(NSString*)IN_strTxt;
-(NSString*) getTimeOnlyFromFormattedSecs:(NSString*)IN_strTxt;

-(void) saveScheduledData:(NSDictionary*)IN_Dict :(ST_Station*) IN_Station;
-(NSMutableDictionary*) getScheduledData:(ST_Station*) IN_Station;

-(int) getTimeRemainingInSecs:(NSDictionary*)IN_Dict;
-(int) getWalkingDistanceInSecs:(NSDictionary*)IN_Dict;
@end
