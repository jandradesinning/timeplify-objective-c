//
//  StatusUtility.m
//  Timeplify
//
//  Created by Anil on 10/01/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import "StatusUtility.h"
#import "ST_Station.h"
#import "Defines.h"

@implementation StatusUtility

-(int) getNowTotalSecs
{
    NSDate* oDateNow = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour |NSCalendarUnitMinute | NSCalendarUnitSecond  fromDate:oDateNow];
    int hour = (int)[components hour];
    int min = (int)[components minute];
    int sec = (int)[components second];
    int iNowTotalSecs = (hour*60*60) + (min*60) + sec;

    return iNowTotalSecs;
}

-(int) getTotalSeconds:(NSString*)IN_strTime
{
   
    
    NSString* strTime = IN_strTime;
    if (strTime == nil) {
        return 0;
    }
    
    NSArray* oArr = [strTime componentsSeparatedByString:@":"];
    if (oArr == nil) {
        return 0;
    }
    
    if ([oArr count] != 3) {
        return 0;
    }
    
    NSString* strHr = [oArr objectAtIndex:0];
    NSString* strMin = [oArr objectAtIndex:1];
    NSString* strSec = [oArr objectAtIndex:2];
    
    int iHour = [strHr intValue];
    int iMin = [strMin intValue];
    int iSec = [strSec intValue];
    
    
    
    int iTotalSecs = (iHour*60*60) + (iMin*60) + iSec;
    return iTotalSecs;
}

#pragma mark Static Data


NSInteger sortScheduledDateComparer(id num1, id num2, void *context)
{
	// Sort Function
	NSMutableDictionary* oSt1 = (NSMutableDictionary*)num1;
	NSMutableDictionary* oSt2 = (NSMutableDictionary*)num2;
    
    int iSec1 = 0;
    NSNumber* oNum1 = [oSt1 objectForKey:@"TRAIN_SECS_FROM_MIDNIGHT"];
    if (oNum1 != nil) {
        iSec1 = [oNum1 intValue];
    }
    
    int iSec2 = 0;
    NSNumber* oNum2 = [oSt2 objectForKey:@"TRAIN_SECS_FROM_MIDNIGHT"];
    if (oNum2 != nil) {
        iSec2 = [oNum2 intValue];
    }
    
	return (iSec1 > iSec2);

}


-(NSMutableDictionary*) getScheduledData:(ST_Station*) IN_Station{
    
    NSString* strDir = @"S";
    if (IN_Station.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        strDir = @"N";
    }
    
    NSString* strKey = [NSString stringWithFormat:@"SCHEDULED_ST_%@_DIR_%@", IN_Station.m_strStationId, strDir];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* oDict = [defaults objectForKey:strKey];
    
    if (oDict == nil) {
        return nil;
    }
    
    NSMutableDictionary* oDictOut = [[NSMutableDictionary alloc] init];
    [oDictOut setObject:oDict forKey:@"scheduled"];
    
    return oDictOut;
}

-(void) saveScheduledData:(NSDictionary*)IN_Dict :(ST_Station*) IN_Station
{
    NSDictionary* oDictSch = [IN_Dict objectForKey:@"scheduled"];
    if (oDictSch == nil) {
        return;
    }
    
    NSString* strDir = @"S";
    if (IN_Station.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        strDir = @"N";
    }
    
    NSString* strKey = [NSString stringWithFormat:@"SCHEDULED_ST_%@_DIR_%@", IN_Station.m_strStationId, strDir];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:oDictSch forKey:strKey];
	[defaults  synchronize];
    
}

-(void)prepareScheduledRecs:(NSMutableArray*)IN_arrRecs
{
 
    int iNowTotalSecs = [self getNowTotalSecs];
    
    for (int i = 0; i <[IN_arrRecs count]; i++) {
        NSMutableDictionary* oDict = [IN_arrRecs objectAtIndex:i];

        NSString* strTime = [oDict objectForKey:@"arrivalTime"];
        if (strTime == nil) {
            continue;
        }
        
        int iTrainTotalSecs = [self getTotalSeconds:strTime];
        
        if (iTrainTotalSecs < iNowTotalSecs) {
            iTrainTotalSecs = iTrainTotalSecs + (24*60*60);
        }
    
        
        [oDict setObject:[NSNumber numberWithInt:iTrainTotalSecs] forKey:@"TRAIN_SECS_FROM_MIDNIGHT"];
    }
    
}


-(NSMutableArray*) getScheduledRecs:(NSDictionary*)IN_Dict
{
    NSMutableArray* oArr = [[NSMutableArray alloc] init];
    
    NSDictionary* oDictSch = [IN_Dict objectForKey:@"scheduled"];
    if (oDictSch == nil) {
        return oArr;
    }
    
    NSArray* oArrData = [oDictSch objectForKey:@"data"];
    if (oArrData == nil) {
        return oArr;
    }
    
    for (int i = 0; i <[oArrData count]; i++) {
        NSDictionary* oD = [oArrData objectAtIndex:i];
        NSMutableDictionary* oD2 = [[NSMutableDictionary alloc] initWithDictionary:oD];
        [oD2 setObject:@"NO" forKey:@"REAL_TIME"];
        
        [oArr addObject:oD2];
    }
    
    return oArr;
    
}


-(NSMutableArray*) removeExtraScheduledRecs:(NSMutableArray*)IN_arrRecs
{
    NSMutableArray* oArrOut = [[NSMutableArray alloc] init];
    
    for (int i= 0; i <[IN_arrRecs count]; i++) {
        
        [oArrOut addObject:[IN_arrRecs objectAtIndex:i]];
        
        if (i >= INT_MAX_SCHEDULED_RECS) {
            break;
        }
    }
    
    
    return oArrOut;
         
}


#pragma mark Realtime Data



-(NSMutableArray*) getRealTimeRecs:(NSDictionary*)IN_Dict
{
    NSMutableArray* oArr = [[NSMutableArray alloc] init];
    
    NSDictionary* oDictReal = [IN_Dict objectForKey:@"realTime"];
    if (oDictReal == nil) {
        return oArr;
    }
    
    NSArray* oArrData = [oDictReal objectForKey:@"data"];
    if (oArrData == nil) {
        return oArr;
    }
    
    for (int i = 0; i <[oArrData count]; i++) {
        NSDictionary* oD = [oArrData objectAtIndex:i];
        NSMutableDictionary* oD2 = [[NSMutableDictionary alloc] initWithDictionary:oD];
        [oD2 setObject:@"YES" forKey:@"REAL_TIME"];
        
        [oArr addObject:oD2];
    }
    
    return oArr;
    
}

-(void)prepareRealtimeRecs:(NSMutableArray*)IN_arrRecs
{
    int iNowTotalSecs = [self getNowTotalSecs];
    
    for (int i = 0; i <[IN_arrRecs count]; i++) {
        NSMutableDictionary* oDict = [IN_arrRecs objectAtIndex:i];
        
        NSString* strTime = [oDict objectForKey:@"arrivalTime"];
        if (strTime == nil) {
            continue;
        }
        
        int iTrainTotalSecs = [self getTotalSeconds:strTime];
        iTrainTotalSecs = iTrainTotalSecs + iNowTotalSecs;
        
        if (iTrainTotalSecs > (24*60*60)) {
            iTrainTotalSecs = iTrainTotalSecs - (24*60*60);
        }
        
        
        [oDict setObject:[NSNumber numberWithInt:iTrainTotalSecs] forKey:@"TRAIN_SECS_FROM_MIDNIGHT"];
    }
    
}


NSInteger sortRealtimeDateComparer(id num1, id num2, void *context)
{
	// Sort Function
	NSMutableDictionary* oSt1 = (NSMutableDictionary*)num1;
	NSMutableDictionary* oSt2 = (NSMutableDictionary*)num2;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"HH:mm:ss"];
    
    
    NSDate* oDt1 = nil;
    NSString* strDt1 = [oSt1 objectForKey:@"arrivalTime"];
    if (strDt1 != nil) {
        oDt1 = [formatter dateFromString:strDt1];
    }
    if (oDt1 == nil) {
        oDt1 = [NSDate date];
    }
    
    NSDate* oDt2 = nil;
    NSString* strDt2 = [oSt2 objectForKey:@"arrivalTime"];
    if (strDt2 != nil) {
        oDt2= [formatter dateFromString:strDt2];
    }
    if (oDt2 == nil) {
        oDt2= [NSDate date];
    }
	
	return ([oDt1 compare:oDt2]);
}

#pragma mark Others


-(int) getTimeRemainingInSecs:(NSDictionary*)IN_Dict
{
    NSString* strTime = [IN_Dict objectForKey:@"arrivalTime"];
    if (strTime == nil) {
        return 0;
    }
    
    int iTrainSecs = [[IN_Dict objectForKey:@"TRAIN_SECS_FROM_MIDNIGHT"]intValue];
    
    int iNowSecs = [self getNowTotalSecs];
  
    
    int iRemaining = iTrainSecs - iNowSecs;
    
    return iRemaining;
   
}



-(NSMutableArray*) getFormattedStatusResult:(NSDictionary*)IN_Dict :(BOOL) IN_bLocalData
{
    NSMutableArray* oArrRecs;
    
    if  (IN_bLocalData == NO)
    {
        oArrRecs = [self getRealTimeRecs:IN_Dict];
        
        if ([oArrRecs count] > 0) {
            [self prepareRealtimeRecs:oArrRecs];
            
            [oArrRecs sortUsingFunction:sortRealtimeDateComparer context:(__bridge void *)(self)];
            
            return oArrRecs;
        }
        else
        {
            oArrRecs = [self getScheduledRecs:IN_Dict];
            
            [self prepareScheduledRecs:oArrRecs];
            
            [oArrRecs sortUsingFunction:sortScheduledDateComparer context:(__bridge void *)(self)];
            
            oArrRecs = [self removeExtraScheduledRecs:oArrRecs];
            
            return oArrRecs;
        }
        
        
    }
    else
    {
        oArrRecs = [self getScheduledRecs:IN_Dict];
        
        [self prepareScheduledRecs:oArrRecs];
        
        [oArrRecs sortUsingFunction:sortScheduledDateComparer context:(__bridge void *)(self)];
        
        oArrRecs = [self removeExtraScheduledRecs:oArrRecs];
        
        return oArrRecs;
    }
    
    
    return nil;
    
}


-(NSString*) getTimeRemaining:(NSDictionary*)IN_Dict
{
    NSString* strTime = [IN_Dict objectForKey:@"arrivalTime"];
    if (strTime == nil) {
        return @"";
    }
    
    int iTrainSecs = [[IN_Dict objectForKey:@"TRAIN_SECS_FROM_MIDNIGHT"]intValue];
    
    int iNowSecs = [self getNowTotalSecs];
    
    if (iTrainSecs < iNowSecs ) {
        return @"";
    }
  
    int iRemaining = iTrainSecs - iNowSecs;
    
    NSString* strTimeRem = [self getFormattedSeconds:iRemaining];
    return strTimeRem;
    
}

-(NSString*) getFormattedSeconds:(int) IN_iSecs
{
    int iMin = IN_iSecs /60.0;
    
    if (iMin <= 60) {
        // TEST_CODE
       // NSString* strRet = [NSString stringWithFormat:@"%d min", IN_iSecs];
        
        
        if (iMin < 1) {
            iMin = 1;
        }
        
        NSString* strRet = [NSString stringWithFormat:@"%d min", iMin];
        return strRet;
    }
    
    double dbHr = iMin /60.0;
    NSString* strRet = [NSString stringWithFormat:@"%0.1lf hours", dbHr];
    return strRet;
    
}

-(NSString*) getTimeOnlyFromFormattedSecs:(NSString*)IN_strTxt
{
    NSString* strTxt = IN_strTxt;
    strTxt = [strTxt stringByReplacingOccurrencesOfString:@" min" withString:@""];
    strTxt = [strTxt stringByReplacingOccurrencesOfString:@" hours" withString:@""];
    return strTxt;
}

-(NSString*) getUnitOnlyFromFormattedSecs:(NSString*)IN_strTxt
{
    if ([IN_strTxt rangeOfString:@"min"].location != NSNotFound) {
        return @"min";
    }
    
    return @"hours";
}


-(NSString*) getWalkingDistance:(NSDictionary*)IN_Dict
{
    
    int iDur = [self getWalkingDistanceInSecs:IN_Dict];
    
    if (iDur < 0) {
        return @"";
    }
    
    NSString* strTime = [self getFormattedSeconds:iDur];
    return strTime;
}



-(int) getWalkingDistanceInSecs:(NSDictionary*)IN_Dict
{
    
    NSArray* oArr = [IN_Dict objectForKey:@"rows"];
    if (oArr == nil) {
        return -1;
    }
    
    if ([oArr count] < 1) {
        return -1;
    }
    
    NSDictionary* oDict = [oArr objectAtIndex:0];
    if (oDict == nil) {
        return -1;
    }

    oArr = [oDict objectForKey:@"elements"];
    if (oArr == nil) {
        return -1;
    }
    
    if ([oArr count] < 1) {
        return -1;
    }
    
    oDict = [oArr objectAtIndex:0];
    if (oDict == nil) {
        return -1 ;
    }
    
    NSDictionary* oDictDur = [oDict objectForKey:@"duration"];
    if (oDictDur == nil) {
        return -1;
    }
    
    NSNumber* oNum = [oDictDur objectForKey:@"value"];
    if (oNum == nil) {
        return -1;
    }
    
    int iDur = [oNum intValue];
    return iDur;

}


-(NSString*) getNextTimeRemaining:(NSMutableArray*)IN_ArrRecs :(int) IN_iCurPos
{
    int iPos = IN_iCurPos +1;
    if ([IN_ArrRecs count] <= iPos) {
        return @"";
    }
    
    NSMutableDictionary* oDict = [IN_ArrRecs objectAtIndex:iPos];
    
    NSString* strText = [self getTimeRemaining:oDict];
    return strText;
}
@end
