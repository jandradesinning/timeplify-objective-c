//
//  ST_Station.h
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ST_Station : NSObject
{
    NSString* m_strStationId;
    NSString* m_strRouteId;
    int m_iIndex;
    NSString* m_strStationName;
    NSString* m_strTrainName;
    NSString* m_strNorthDirection;
    NSString* m_strSouthDirection;
    double m_dbLatitude;
    double m_dbLongitude;
    int m_iSelectedDirection;
    int m_iTemporaryDirection;
    double m_dbDistanceFromGPS;
    int m_iOrder;
}
@property (strong, nonatomic) NSString* m_strStationId;
@property (strong, nonatomic) NSString* m_strRouteId;
@property (readwrite, assign) int m_iIndex;
@property (strong, nonatomic) NSString* m_strStationName;
@property (strong, nonatomic) NSString* m_strTrainName;
@property (strong, nonatomic) NSString* m_strNorthDirection;
@property (strong, nonatomic) NSString* m_strSouthDirection;
@property (readwrite, assign) double m_dbLatitude;
@property (readwrite, assign) double m_dbLongitude;
@property (readwrite, assign) int m_iOrder;
@property (readwrite, assign) int m_iSelectedDirection;
@property (readwrite, assign) int m_iTemporaryDirection;

@property (readwrite, assign) double m_dbDistanceFromGPS;
@end
