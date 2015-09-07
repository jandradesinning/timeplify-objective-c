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
#import "Utility.h"
#import "DataManager.h"
#import "GlobalCaller.h"
#import "ST_Train.h"

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


#pragma mark ServiceStatus


-(UIColor*) getServiceStatusColor:(NSDictionary*)IN_Dict
{
    UIColor* oClr = [UIColor blackColor];
    
    NSString* strKey = [self getServiceStatusfromDefault:IN_Dict];
    if (strKey == nil) {
        return oClr;
    }
    
    if ([strKey length] < 1) {
        return oClr;
    }
    
    NSMutableDictionary* oDict = [Utility getDictFromDefault:@"DICT_APP_SETTINGS"];
    if (oDict == nil) {
        return oClr;
    }
    
    NSDictionary* oD3  = [oDict objectForKey:@"data"];
    if (oD3 == nil) {
        return oClr;
    }
    
    NSDictionary* oD4  = [oD3 objectForKey:@"subway"];
    if (oD4 == nil) {
        return oClr;
    }
    
    
    NSDictionary* oD5  = [oD4 objectForKey:@"serviceStatuses"];
    if (oD5 == nil) {
        return oClr;
    }
    
    NSDictionary* oD6 = [oD5 objectForKey:strKey];
    if (oD6 == nil) {
        return oClr;
    }
    
    
    NSString* strClr = [oD6 objectForKey:@"color"];
    if (strClr == nil) {
        return oClr;
    }
    
    strClr = [strClr stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    oClr = [Utility colorFromHexString:strClr];
    return oClr;
    
}

-(NSString*) getServiceStatusText:(NSDictionary*)IN_Dict
{
    NSString* strKey = [self getServiceStatusfromDefault:IN_Dict];
    if (strKey == nil) {
        return @"";
    }
    
    if ([strKey length] < 1) {
        return @"";
    }
    
    NSMutableDictionary* oDict = [Utility getDictFromDefault:@"DICT_APP_SETTINGS"];
    if (oDict == nil) {
        return @"";
    }
    
    NSDictionary* oD3  = [oDict objectForKey:@"data"];
    if (oD3 == nil) {
        return @"";
    }
    
    NSDictionary* oD4  = [oD3 objectForKey:@"subway"];
    if (oD4 == nil) {
        return @"";
    }
    
    
    NSDictionary* oD5  = [oD4 objectForKey:@"serviceStatuses"];
    if (oD5 == nil) {
        return @"";
    }
    
    NSDictionary* oD6 = [oD5 objectForKey:strKey];
    if (oD6 == nil) {
        return @"";
    }
    
    NSString* strTxt = [oD6 objectForKey:@"text"];
    
    return strTxt;
    
    
}


-(NSMutableAttributedString*) getServiceStatusFormattedText:(NSString*)IN_strStatus :(UIColor*)IN_Color :(BOOL)IN_bRealTime
{
    NSMutableAttributedString *strAttrib;
    
    UIFont* oFontMain = [UIFont boldSystemFontOfSize:20];
    UIFont* oFontDate = [UIFont systemFontOfSize:10.0];
    
    NSString* strTime = [Utility getStringFromDefault:@"ALL_SERVICE_STATUSES_FEED_TIME"];
    if (([strTime length] < 1)||(IN_bRealTime == YES)) {
        strAttrib = [[NSMutableAttributedString alloc] initWithString:IN_strStatus];
        int iLen = (int)[IN_strStatus length];
        [strAttrib addAttribute:NSFontAttributeName
                          value:oFontMain
                          range:NSMakeRange(0, iLen)];
        
        [strAttrib addAttribute:NSForegroundColorAttributeName
                          value:IN_Color
                          range:NSMakeRange(0, iLen)];
        
    }
    else
    {
        long iTime = [strTime longLongValue];
        NSDate* oDate = [NSDate dateWithTimeIntervalSince1970:iTime];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"hh:mm a"];
        NSString *strDate = [dateFormatter stringFromDate:oDate];
        
        NSString *dateString = [NSString stringWithFormat:@"Last known @ %@", strDate];
        
        NSString* strText = [NSString stringWithFormat:@"%@\n%@", IN_strStatus, dateString];
        
        strAttrib = [[NSMutableAttributedString alloc] initWithString:strText];
        int iLen1 = (int)[IN_strStatus length];
        int iLen2 = (int)[dateString length];
        
        
        [strAttrib addAttribute:NSFontAttributeName
                          value:oFontMain
                          range:NSMakeRange(0, iLen1)];
        
        [strAttrib addAttribute:NSForegroundColorAttributeName
                          value:IN_Color
                          range:NSMakeRange(0, iLen1)];
        
        
        [strAttrib addAttribute:NSFontAttributeName
                          value:oFontDate
                          range:NSMakeRange((iLen1+1), iLen2)];
        
        [strAttrib addAttribute:NSForegroundColorAttributeName
                          value:[UIColor blackColor]
                          range:NSMakeRange((iLen1+1), iLen2)];
        
        
    }
    
    
    return strAttrib;
    
}


-(NSString*) getServiceStatusfromDefault:(NSDictionary*)IN_Dict
{
    NSString* strRoute = [IN_Dict objectForKey:@"routeId"];
    if (strRoute == nil) {
        return @"";
    }
    
    NSDictionary* oDictStatus = [Utility getDictFromDefault:@"ALL_SERVICE_STATUSES"];
    if (oDictStatus == nil) {
        return @"";
    }
    
    NSString* strStatus = [oDictStatus objectForKey:strRoute];
    if (strStatus == nil) {
        return @"";
    }
    
    return strStatus;
    
}

-(void) storeServiceStatusInDefault:(NSDictionary*)IN_Dict
{
    NSDictionary* oDictStatus = [IN_Dict objectForKey:@"serviceStatus"];
    if (oDictStatus == nil) {
        return;
    }
    
    NSDictionary* oDictReal = [IN_Dict objectForKey:@"realTime"];
    if (oDictReal != nil) {
        NSString* strFeedTime = [oDictReal objectForKey:@"feedTime"];
        if (strFeedTime != nil) {
            [Utility saveStringInDefault:@"ALL_SERVICE_STATUSES_FEED_TIME" :strFeedTime];
        }
    }
    

    
    NSMutableDictionary* oD2 = [[NSMutableDictionary alloc] initWithDictionary:oDictStatus];
    [Utility saveDictInDefault:@"ALL_SERVICE_STATUSES" :oD2];
    
}

-(BOOL) isServiceStatusStoredInDefault
{
  
    
    NSDictionary* oDictStatus = [Utility getDictFromDefault:@"ALL_SERVICE_STATUSES"];
    if (oDictStatus == nil) {
        return NO;
    }
    
    return YES;
    
}

#pragma mark Local DB Scheduled Data


-(BOOL) isLocalDBExceptionDate:(NSString*)IN_strDate
{
    
    NSDate* oDtNow = [NSDate date];
    oDtNow = [Utility getDateWithoutTime:oDtNow];
    
    if (IN_strDate == nil) {
        return NO;
    }
    
    if ( IN_strDate == (NSString *)[NSNull null] )
    {
        return NO;
    }
    
    
    NSString* strFormat = @"yyyyMMdd";
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateFormat:strFormat];
    
	NSDate* oDt = [format dateFromString:IN_strDate];
    if (oDt == nil) {
        return NO;
    }
    
    oDt = [Utility getDateWithoutTime:oDt];
    
    if ([oDtNow compare:oDt] == NSOrderedSame) {
        return YES;
    }
    
    return NO;
}

-(void) removeLocalDBExceptionDates:(NSMutableArray*)IN_arrRecs
{
    
    NSMutableArray* oArrExceptServices = [[NSMutableArray alloc] init];
    
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"ExceptionDate.plist" ofType:nil];
    NSArray* oArr = [NSArray arrayWithContentsOfFile:filepath];
    
    for (int i = 0; i < [oArr count]; i++) {
        NSDictionary* oDict = [oArr objectAtIndex:i];
        
        
        NSString* strExpDate = [oDict objectForKey:@"Date"];
        NSString* strServiceId = [oDict objectForKey:@"ServiceId"];
       
        if ([self isLocalDBExceptionDate:strExpDate]) {
            [oArrExceptServices addObject:strServiceId];
        }
    }

    
    for (int i =  ((int)[IN_arrRecs count] -1); i >= 0; i--) {
        NSMutableDictionary* oDict = [IN_arrRecs objectAtIndex:i];
         
        NSString* strService = [oDict objectForKey:@"ServiceId"];
        BOOL bExcep = NO;
        for (int j = 0; j < [oArrExceptServices count]; j++) {
            NSString* strExcepService = [oArrExceptServices objectAtIndex:j];
            if ([strExcepService isEqualToString:strService]) {
                bExcep = YES;
                break;
            }
        }
        
        if (bExcep == YES) {
            [IN_arrRecs removeObjectAtIndex:i];
        }
        
    }
    
}


-(NSMutableArray*) getLocalDBScheduledDataAfterExceptions:(NSMutableArray*) IN_arrAllData
{
    NSDate* oDtNow = [NSDate date];
    oDtNow = [Utility getDateWithoutTime:oDtNow];
    
    
    NSMutableArray* oArrFinalData = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [IN_arrAllData count]; i++) {
        NSDictionary* oDict = [IN_arrAllData objectAtIndex:i];
        NSString* strService = [oDict objectForKey:@"ServiceId"];
        if (strService == nil) {
            continue;
        }
        
        
        NSString* strTime = [oDict objectForKey:@"arrivalTime"];
        if (strTime == nil) {
            continue;
        }
        
        int iTrainTotalSecs = [self getTotalSeconds:strTime];
        
        NSDate* oDtTemp = [oDtNow dateByAddingTimeInterval:iTrainTotalSecs];
        
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        [gregorian setLocale:[NSLocale currentLocale]];
        NSDateComponents *weekdayComponents =[gregorian components:NSWeekdayCalendarUnit fromDate:oDtTemp];
        int iWeek = (int)[weekdayComponents weekday];
        
        if ([strService rangeOfString:@"WKD" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            if (iWeek == 7) {
                continue;
            }
            if (iWeek == 1) {
                continue;
            }
        }
        
        if ([strService rangeOfString:@"SAT" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            if (iWeek != 7) {
                continue;
            }
        }
        
        if ([strService rangeOfString:@"SUN" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            if (iWeek != 1) {
                continue;
            }
        }
        
        if ([strService rangeOfString:@"MON" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            if (iWeek != 2) {
                continue;
            }
        }

        
        [oArrFinalData addObject:oDict];
        
    }

    
    [self removeLocalDBExceptionDates:oArrFinalData];
    
    
    return oArrFinalData;
}


-(NSMutableDictionary*) getLocalDBScheduledData:(ST_Station*) IN_Station
{
    NSString* strDir = @"S";
    if (IN_Station.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
        strDir = @"N";
    }
    
    NSMutableArray* oArr = [DataManager getLocalScheduledData:IN_Station.m_strStationId: strDir];
    
    oArr = [self getLocalDBScheduledDataAfterExceptions:oArr];
    
    NSMutableDictionary* oDictData = [[NSMutableDictionary alloc] init];
    [oDictData setObject:oArr forKey:@"data"];
    
                            
    NSMutableDictionary* oDictOut = [[NSMutableDictionary alloc] init];
    [oDictOut setObject:oDictData forKey:@"scheduled"];
    
    return oDictOut;

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


-(NSMutableArray*) removeExtraScheduledRecs:(NSMutableArray*)IN_arrRecs :(ST_Station*)IN_curStation
{
    NSMutableArray* oArrOut = [[NSMutableArray alloc] init];
    
    int iCount = 0;
    
    for (int i= 0; i <[IN_arrRecs count]; i++) {
        
        NSMutableDictionary* oDict = [IN_arrRecs objectAtIndex:i];
        
        NSString* strRouteId = [oDict objectForKey:@"routeId"];
        if ([strRouteId isEqualToString:IN_curStation.m_strRouteId]) {
            iCount++;
        }
        
        [oArrOut addObject:[IN_arrRecs objectAtIndex:i]];
        
        if (iCount >= INT_MAX_SCHEDULED_RECS) {
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

-(NSMutableDictionary*) getCurrentDisplayingDict:(NSMutableArray*)IN_arrRecs :(ST_Station*)IN_curStation
{
    
    for (int i= 0; i <[IN_arrRecs count]; i++) {
        
        NSMutableDictionary* oDict = [IN_arrRecs objectAtIndex:i];
        
        NSString* strRouteId = [oDict objectForKey:@"routeId"];
        if ([strRouteId isEqualToString:IN_curStation.m_strRouteId]) {
            return oDict;
        }
    }
    
    return nil;
}

-(NSMutableDictionary*) getNextDisplayingDict:(NSMutableArray*)IN_arrRecs :(ST_Station*)IN_curStation
{
    int iCount = 0;
    
    for (int i= 0; i <[IN_arrRecs count]; i++) {
        
        NSMutableDictionary* oDict = [IN_arrRecs objectAtIndex:i];
        
        NSString* strRouteId = [oDict objectForKey:@"routeId"];
        if ([strRouteId isEqualToString:IN_curStation.m_strRouteId]) {
            if (iCount > 0) {
                return oDict;
            }
            iCount++;
        }
    }
    
    return nil;
}



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


-(void) assignLastStations:(NSMutableArray*)IN_arrRecs :(ST_Station*)IN_curStation
{
    NSMutableArray* arrAllTrains = [GlobalCaller getAllTrainsArray];
    
    for (int i=0; i <[IN_arrRecs count]; i++) {
        NSMutableDictionary* oDict = [IN_arrRecs objectAtIndex:i];
        NSString* strId = [oDict objectForKey:@"routeId"];
        
        for (int j=0; j <[arrAllTrains count]; j++) {
            ST_Train* oTrain = [arrAllTrains objectAtIndex:j];
            if ([oTrain.m_strId isEqualToString:strId]) {
                
                if (IN_curStation.m_iTemporaryDirection == INT_DIRECTION_NORTH) {
                    [oDict setObject:oTrain.m_strNorthStationName forKey:@"LAST_STATION"];
                }
                
                if (IN_curStation.m_iTemporaryDirection == INT_DIRECTION_SOUTH) {
                    [oDict setObject:oTrain.m_strSouthStationName forKey:@"LAST_STATION"];
                }
                
                break;
            }
        }
        
    }
}


-(ST_Station*) getEarlyStationRouteForGPSNearest: (NSMutableArray*)IN_arrNextTrains : (ST_Station*)IN_curStation :(NSMutableArray*)IN_arrGPSStations
{
    if ([IN_arrNextTrains count] < 1) {
        return nil;
    }
    
    NSMutableDictionary* oDict = [IN_arrNextTrains objectAtIndex:0];
    NSString* strRouteId = [oDict objectForKey:@"routeId"];
    
    for (int i=0; i <[IN_arrGPSStations count]; i++) {
        ST_Station* oStation = [IN_arrGPSStations objectAtIndex:i];
        
        if ([strRouteId isEqualToString:oStation.m_strRouteId]) {
            oStation.m_iSelectedDirection = IN_curStation.m_iSelectedDirection;
            oStation.m_iTemporaryDirection = IN_curStation.m_iTemporaryDirection;
            return oStation;
        }
        
    }
    
    return nil;
}


-(NSMutableArray*) getFormattedStatusResult:(NSDictionary*)IN_Dict :(BOOL) IN_bLocalData :(ST_Station*)IN_curStation
{
    NSMutableArray* oArrRecs;
    
    if  (IN_bLocalData == NO)
    {
        oArrRecs = [self getRealTimeRecs:IN_Dict];
        
        if ([oArrRecs count] > 0) {
            [self prepareRealtimeRecs:oArrRecs];
            
            [oArrRecs sortUsingFunction:sortRealtimeDateComparer context:(__bridge void *)(self)];
            
            [self assignLastStations:oArrRecs :IN_curStation];
            
            return oArrRecs;
        }
        else
        {
            oArrRecs = [self getScheduledRecs:IN_Dict];
            
            [self prepareScheduledRecs:oArrRecs];
            
            [oArrRecs sortUsingFunction:sortScheduledDateComparer context:(__bridge void *)(self)];
            
            oArrRecs = [self removeExtraScheduledRecs:oArrRecs:IN_curStation];
            
            [self assignLastStations:oArrRecs :IN_curStation];
            
            return oArrRecs;
        }
        
        
    }
    else
    {
        oArrRecs = [self getScheduledRecs:IN_Dict];
        
        [self prepareScheduledRecs:oArrRecs];
        
        [oArrRecs sortUsingFunction:sortScheduledDateComparer context:(__bridge void *)(self)];
        
        oArrRecs = [self removeExtraScheduledRecs:oArrRecs:IN_curStation];
        
        [self assignLastStations:oArrRecs :IN_curStation];
        
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
        
        if (iMin < 0) {
            iMin = 0;
        }
        
        // TEST_CODE
        //NSString* strRet = [NSString stringWithFormat:@"%0.2lf min", (IN_iSecs/60.0)];
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


-(NSString*) getNextTimeRemaining:(NSMutableArray*)IN_ArrRecs :(ST_Station*)IN_curStation
{
    
    NSMutableDictionary* oDict = [self getNextDisplayingDict:IN_ArrRecs :IN_curStation];
    if (oDict == nil) {
        return @"";
    }
    
    NSString* strText = [self getTimeRemaining:oDict];
    return strText;
    
}

-(BOOL) doesRouteHaveLive:(NSString*)IN_strRoute
{
    
    NSString* strIn = [IN_strRoute uppercaseString];
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"LiveTrains.plist" ofType:nil];
    NSArray* oArr = [NSArray arrayWithContentsOfFile:filepath];
    
    for (int i = 0; i < [oArr count]; i++) {
        NSString* strRoute = [oArr objectAtIndex:i];
        
        NSString* strUpperRoute = [strRoute uppercaseString];
        
        if ([strUpperRoute isEqualToString:strIn]) {
            return YES;
        }
        
    }
    
    return NO;
}
@end
