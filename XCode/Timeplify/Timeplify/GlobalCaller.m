//
//  GlobalCaller.m
//  Timeplify
//
//  Created by Anil on 08/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "GlobalCaller.h"
#import "AppDelegate.h"
#import "ST_Station.h"
#import "Utility.h"
#import "ST_Train.h"

@implementation GlobalCaller


+(NSMutableArray*) getAllTrainsArray
{
    NSDictionary* oDict = (NSDictionary*)[Utility getObjectFromDefault:@"SERVER_STATIC_DATA"];
    NSArray* arrRoutes = [oDict objectForKey:@"routes"];
    
    NSMutableArray* oArr = [[NSMutableArray alloc] init];
    
    for (int i=0; i <[arrRoutes count]; i++) {
        NSDictionary* oDict = [arrRoutes objectAtIndex:i];
        ST_Train* oTrain = [[ST_Train alloc] init];
        oTrain.m_iIndex = i;
        oTrain.m_strId  = [oDict objectForKey:@"id"];
        oTrain.m_strName = [oDict objectForKey:@"name"];
        oTrain.m_strImage = [oDict objectForKey:@"id"];
        oTrain.m_bSelected = NO;
        oTrain.m_arrStations = [oDict objectForKey:@"stations"];
        [oArr addObject:oTrain];
    }

    return oArr;
}

+(NSMutableArray*) getFavTrainsArray
{
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    return appDel.m_arrFavoriteTrains;
    
}

+(NSMutableArray*) getFavStationsArray
{
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    return appDel.m_arrFavoriteStations;
    
}



+(void) updateFavTrain:(ST_Train*)IN_Train
{
    NSMutableArray* oArrFavTrains = [GlobalCaller getFavTrainsArray];
    
    ST_Train* oTrainExisting = nil;
    
    for (int i=0; i <[oArrFavTrains count]; i++) {
        ST_Train* oTr = [oArrFavTrains objectAtIndex:i];
        if ([oTr.m_strId isEqualToString:IN_Train.m_strId]) {
            oTrainExisting = oTr;
            break;
        }
    }
    
    if (IN_Train.m_bSelected == NO) {
        if (oTrainExisting !=nil) {
            [oArrFavTrains removeObject:oTrainExisting];
        }
        return;
    }
    else
    {
        if (oTrainExisting !=nil) {
            
            oTrainExisting.m_bSelected = YES;
        }
        else
        {
            [oArrFavTrains addObject:IN_Train];
        }
    }
    
}



+(void) updateFavStation:(ST_Station*)IN_Station
{
    NSMutableArray* oArrFavStations = [GlobalCaller getFavStationsArray];
    
    ST_Station* oStationExisting = nil;
    
    for (int i=0; i <[oArrFavStations count]; i++) {
        ST_Station* oSt = [oArrFavStations objectAtIndex:i];
        if ([oSt.m_strStationId isEqualToString:IN_Station.m_strStationId]) {
            oStationExisting = oSt;
            break;
        }
    }
    
    if (IN_Station.m_iSelectedDirection < 1) {
        if (oStationExisting !=nil) {
            [oArrFavStations removeObject:oStationExisting];
        }
        return;
    }
    else
    {
        if (oStationExisting !=nil) {
            
            oStationExisting.m_iSelectedDirection = IN_Station.m_iSelectedDirection;
        }
        else
        {
            [oArrFavStations addObject:IN_Station];
        }
    }
    
}

@end
