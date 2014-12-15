//
//  ST_Station.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "ST_Station.h"

@implementation ST_Station

@synthesize m_iStationId;
@synthesize m_iRouteId;
@synthesize m_iIndex;
@synthesize m_strName;
@synthesize m_strNorthDirection;
@synthesize m_strSouthDirection;
@synthesize m_dbLatitude;
@synthesize m_dbLongitude;
@synthesize m_bSelected;
@synthesize m_iSelectedDirection;


- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeObject:[NSNumber numberWithInteger:m_iStationId] forKey:@"KEY_STATION_ID"];
    [aCoder encodeObject:[NSNumber numberWithInteger:m_iRouteId] forKey:@"KEY_ROUTE_ID"];
    [aCoder encodeObject:[NSNumber numberWithInteger:m_iIndex] forKey:@"KEY_INDEX"];
    [aCoder encodeObject:m_strName forKey:@"KEY_NAME"];
    [aCoder encodeObject:m_strNorthDirection forKey:@"KEY_NORTH_DIRECTION"];
    [aCoder encodeObject:m_strSouthDirection forKey:@"KEY_SOUTH_DIRECTION"];
    [aCoder encodeObject:[NSNumber numberWithDouble:m_dbLatitude] forKey:@"KEY_LATITUDE"];
    [aCoder encodeObject:[NSNumber numberWithDouble:m_dbLongitude] forKey:@"KEY_LONGITUDE"];
    [aCoder encodeObject:[NSNumber numberWithBool:m_bSelected] forKey:@"KEY_SELECTED"];
    [aCoder encodeObject:[NSNumber numberWithInteger:m_iSelectedDirection] forKey:@"KEY_SELECTED_DIRECTION"];
    
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
        
        m_iStationId = [[aDecoder decodeObjectForKey:@"KEY_STATION_ID"] intValue];
        m_iRouteId = [[aDecoder decodeObjectForKey:@"KEY_ROUTE_ID"] intValue];
        m_iIndex = [[aDecoder decodeObjectForKey:@"KEY_INDEX"] intValue];
        m_strName = [aDecoder decodeObjectForKey:@"KEY_NAME"];
        m_strNorthDirection = [aDecoder decodeObjectForKey:@"KEY_NORTH_DIRECTION"];
        m_strSouthDirection = [aDecoder decodeObjectForKey:@"KEY_SOUTH_DIRECTION"];
        m_dbLatitude = [[aDecoder decodeObjectForKey:@"KEY_LATITUDE"] intValue];
        m_dbLongitude = [[aDecoder decodeObjectForKey:@"KEY_LONGITUDE"] intValue];
        m_bSelected = [[aDecoder decodeObjectForKey:@"KEY_SELECTED"] boolValue];
        m_iSelectedDirection = [[aDecoder decodeObjectForKey:@"KEY_SELECTED_DIRECTION"] intValue];
        
    }
    return self;
}



@end
