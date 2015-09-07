//
//  NearestStation.m
//  Timeplify
//
//  Created by Anil on 26/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "NearestStation.h"
#import "AppDelegate.h"
#import "Utility.h"
#import "ST_Station.h"

#import <CoreLocation/CoreLocation.h>
#import "Defines.h"
#import "ST_Train.h"
#import "GlobalCaller.h"
#import "DataManager.h"

@implementation NearestStation


#pragma mark - NEXT/PREV Stations


-(ST_Station*) getPrevStationofStation:(ST_Station*) IN_Station :(int)IN_iDirection
{
    if (IN_Station.m_strRouteId == nil) {
        return nil;
    }
    
    NSMutableArray* oArrStations = [DataManager getStationsOfTrain:IN_Station.m_strRouteId];
    
    int iLast = 0;
    if (IN_iDirection == INT_DIRECTION_NORTH) {
        iLast++;
    }
    
    for (int i= ((int)[oArrStations count]-1); i >= iLast; i--) {
        ST_Station* oStation =  [oArrStations objectAtIndex:i];
        if (oStation.m_iOrder < IN_Station.m_iOrder) {
            return oStation;
        }
        
    }
    
    return nil;
}



-(ST_Station*) getNextStationofStation:(ST_Station*) IN_Station :(int)IN_iDirection
{
    if (IN_Station.m_strRouteId == nil) {
        return nil;
    }
    
    NSMutableArray* oArrStations = [DataManager getStationsOfTrain:IN_Station.m_strRouteId];
    
    int iCount = (int)[oArrStations count];
    if (IN_iDirection == INT_DIRECTION_SOUTH) {
        iCount--;
    }
    
    for (int i = 0; i <iCount; i++) {
        ST_Station* oStation =  [oArrStations objectAtIndex:i];
        if (oStation.m_iOrder > IN_Station.m_iOrder) {
            return oStation;
        }
        
    }
    
    return nil;
}



#pragma mark - Get Station with Route


-(NSMutableArray*) getStationsWithRoutesOfStation:(ST_Station*) IN_Station
{
    NSMutableArray* oArrFavTrains = [GlobalCaller getFavTrainsArray];
    
    NSMutableArray* oArrStations = [DataManager getStationsOfTrainStopInStation:IN_Station.m_strStationId];
    
    
    NSMutableArray* oArrFavoriteOut = [[NSMutableArray alloc] init];
    
    
    for (int i = 0; i <[oArrStations count]; i++) {
        ST_Station* oStation =  [oArrStations objectAtIndex:i];
       
        for (int j = 0; j < [oArrFavTrains count]; j++) {
            ST_Train* oTrain = [oArrFavTrains objectAtIndex:j];
            if ([oTrain.m_strId isEqualToString:oStation.m_strStationId]) {
                [oArrFavoriteOut addObject:oStation];
            }
        }
        
    }
    
    if ([oArrFavoriteOut count] > 0) {
        return oArrFavoriteOut;
    }
    
    
    return  oArrStations;
}

#pragma mark - Others





-(void) UpdateLocationDistanceFromCenter:(NSMutableArray*)IN_arrStations
{
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    
	for (int i = 0; i < [IN_arrStations count]; i++)
	{
		ST_Station* oStation = (ST_Station*) [IN_arrStations objectAtIndex:i];
		
		oStation.m_dbDistanceFromGPS =  [Utility getLocationDistance:appDel.m_GPSCoordinate.latitude
																		 :appDel.m_GPSCoordinate.longitude
																		 :oStation.m_dbLatitude
																		 :oStation.m_dbLongitude];
	}
	
}



NSInteger sortStationComparer(id num1, id num2, void *context)
{
	// Sort Function
	ST_Station* oStation1 = (ST_Station*)num1;
	ST_Station* oStation2 = (ST_Station*)num2;
	
	
	return (oStation1.m_dbDistanceFromGPS > oStation2.m_dbDistanceFromGPS);
}

-(NSMutableArray*) getNearestStations{
    
    //NSLog(@"getNearestStations");
    
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    if (appDel.m_iGPSStatus != 2)
    {
        return nil;
    }
    
    
   
    
    NSMutableArray* oArrStations = [DataManager getAllStations];
    
    [self UpdateLocationDistanceFromCenter:oArrStations];
    
    [oArrStations sortUsingFunction:sortStationComparer context:(__bridge void *)(self)];
    
    
    NSMutableArray* oArrNearStations = [[NSMutableArray alloc] init];
    
    for (int i=0; i <[oArrStations count]; i++) {
        
        ST_Station* oStation = (ST_Station*) [oArrStations objectAtIndex:i];
        
        if (oStation.m_dbDistanceFromGPS > INT_MAX_STATION_DISTANCE ) {
            break;
        }
        
        [oArrNearStations addObject:oStation];
  
    }
    
    
    return oArrNearStations;
}

-(NSMutableArray*) getStationsWithRoutesOfFirstNearestStation
{
    NSMutableArray* oArrNearStations = [self getNearestStations];
    if (oArrNearStations == nil) {
        return nil;
    }
    
    if ([oArrNearStations count] < 1) {
        return nil;
    }
    
    
    NSMutableArray* oArrOut = [[NSMutableArray alloc] init];
    
    NSMutableArray* oArrFavStations = [GlobalCaller getFavStationsArray];
    
    for (int i = 0; i < [oArrNearStations count]; i++)
	{
		ST_Station* oStation = (ST_Station*) [oArrNearStations objectAtIndex:i];

        for (int j = 0; j <[oArrFavStations count]; j++) {
            ST_Station* oFavStation = [oArrFavStations objectAtIndex:j];
            
            if ([oStation.m_strStationId isEqualToString:oFavStation.m_strStationId]) {
                [oArrOut addObject:oFavStation];
            }
            
        }
        
        if ([oArrOut count] > 0) {
            return oArrOut;
        }
    }
    
    
    
    
    ST_Station* oStation = (ST_Station*) [oArrNearStations objectAtIndex:0];
    oArrOut = [self getStationsWithRoutesOfStation:oStation];
    return oArrOut;
    
}

@end
