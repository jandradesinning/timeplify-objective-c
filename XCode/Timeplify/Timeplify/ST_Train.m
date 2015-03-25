//
//  ST_Train.m
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "ST_Train.h"

@implementation ST_Train

@synthesize m_strId;
@synthesize m_iIndex;
@synthesize m_strName;
@synthesize m_strImage;
@synthesize m_strNorthStationId;
@synthesize m_strSouthStationId;
@synthesize m_strNorthStationName;
@synthesize m_strSouthStationName;
@synthesize m_bSelected;


- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeObject:m_strId forKey:@"KEY_ID"];
    [aCoder encodeObject:[NSNumber numberWithInteger:m_iIndex] forKey:@"KEY_INDEX"];
    [aCoder encodeObject:m_strName forKey:@"KEY_NAME"];
    [aCoder encodeObject:m_strImage forKey:@"KEY_IMAGE"];
    [aCoder encodeObject:m_strNorthStationId forKey:@"KEY_NORTH_STATION_ID"];
    [aCoder encodeObject:m_strSouthStationId forKey:@"KEY_SOUTH_STATION_ID"];
    [aCoder encodeObject:m_strNorthStationName forKey:@"KEY_NORTH_STATION_NAME"];
    [aCoder encodeObject:m_strSouthStationName forKey:@"KEY_SOUTH_STATION_NAME"];
    [aCoder encodeObject:[NSNumber numberWithBool:m_bSelected] forKey:@"KEY_SELECTED"];
   
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
        
        m_strId = [aDecoder decodeObjectForKey:@"KEY_ID"];
        m_iIndex = [[aDecoder decodeObjectForKey:@"KEY_INDEX"] intValue];
        m_strName = [aDecoder decodeObjectForKey:@"KEY_NAME"];
        m_strImage = [aDecoder decodeObjectForKey:@"KEY_IMAGE"];
        m_strNorthStationId = [aDecoder decodeObjectForKey:@"KEY_NORTH_STATION_ID"];
        m_strSouthStationId = [aDecoder decodeObjectForKey:@"KEY_SOUTH_STATION_ID"];
        m_strNorthStationName = [aDecoder decodeObjectForKey:@"KEY_NORTH_STATION_NAME"];
        m_strSouthStationName = [aDecoder decodeObjectForKey:@"KEY_SOUTH_STATION_NAME"];
        m_bSelected = [[aDecoder decodeObjectForKey:@"KEY_SELECTED"] boolValue];

        
    }
    return self;
}


@end
