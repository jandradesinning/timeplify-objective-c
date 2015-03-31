//
//  ST_Station.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "ST_Station.h"

@implementation ST_Station

@synthesize m_strStationId;
@synthesize m_strRouteId;
@synthesize m_iIndex;
@synthesize m_strStationName;
@synthesize m_strTrainName;
@synthesize m_strNorthDirection;
@synthesize m_strSouthDirection;
@synthesize m_dbLatitude;
@synthesize m_dbLongitude;
@synthesize m_iOrder;
@synthesize m_iSelectedDirection;
@synthesize m_iTemporaryDirection;
@synthesize m_dbDistanceFromGPS;
@synthesize m_dbWalkingDistance;


- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeObject:m_strStationId forKey:@"KEY_STATION_ID"];
    [aCoder encodeObject:m_strRouteId forKey:@"KEY_ROUTE_ID"];
    [aCoder encodeObject:[NSNumber numberWithInteger:m_iIndex] forKey:@"KEY_INDEX"];
    [aCoder encodeObject:m_strStationName forKey:@"KEY_STATION_NAME"];
    [aCoder encodeObject:m_strTrainName forKey:@"KEY_TRAIN_NAME"];
    [aCoder encodeObject:m_strNorthDirection forKey:@"KEY_NORTH_DIRECTION"];
    [aCoder encodeObject:m_strSouthDirection forKey:@"KEY_SOUTH_DIRECTION"];
    [aCoder encodeObject:[NSNumber numberWithDouble:m_dbLatitude] forKey:@"KEY_LATITUDE"];
    [aCoder encodeObject:[NSNumber numberWithDouble:m_dbLongitude] forKey:@"KEY_LONGITUDE"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_iOrder] forKey:@"KEY_ORDER"];
    [aCoder encodeObject:[NSNumber numberWithInteger:m_iSelectedDirection] forKey:@"KEY_SELECTED_DIRECTION"];
    
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
        
        m_strStationId = [aDecoder decodeObjectForKey:@"KEY_STATION_ID"];
        m_strRouteId = [aDecoder decodeObjectForKey:@"KEY_ROUTE_ID"];
        m_iIndex = [[aDecoder decodeObjectForKey:@"KEY_INDEX"] intValue];
        m_strStationName = [aDecoder decodeObjectForKey:@"KEY_STATION_NAME"];
        m_strTrainName = [aDecoder decodeObjectForKey:@"KEY_TRAIN_NAME"];
        m_strNorthDirection = [aDecoder decodeObjectForKey:@"KEY_NORTH_DIRECTION"];
        m_strSouthDirection = [aDecoder decodeObjectForKey:@"KEY_SOUTH_DIRECTION"];
        m_dbLatitude = [[aDecoder decodeObjectForKey:@"KEY_LATITUDE"] doubleValue];
        m_dbLongitude = [[aDecoder decodeObjectForKey:@"KEY_LONGITUDE"] doubleValue];
        m_iOrder = [[aDecoder decodeObjectForKey:@"KEY_ORDER"] intValue];
        m_iSelectedDirection = [[aDecoder decodeObjectForKey:@"KEY_SELECTED_DIRECTION"] intValue];
        
    }
    return self;
}



@end
