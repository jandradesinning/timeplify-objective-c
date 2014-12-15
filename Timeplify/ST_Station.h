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
    int m_iStationId;
    int m_iRouteId;
    int m_iIndex;
    NSString* m_strName;
    NSString* m_strNorthDirection;
    NSString* m_strSouthDirection;
    double m_dbLatitude;
    double m_dbLongitude;
    BOOL m_bSelected;
    int m_iSelectedDirection;
}
@property (readwrite, assign) int m_iStationId;
@property (readwrite, assign) int m_iRouteId;
@property (readwrite, assign) int m_iIndex;
@property (strong, nonatomic) NSString* m_strName;
@property (strong, nonatomic) NSString* m_strNorthDirection;
@property (strong, nonatomic) NSString* m_strSouthDirection;
@property (readwrite, assign) double m_dbLatitude;
@property (readwrite, assign) double m_dbLongitude;
@property (readwrite, assign) BOOL m_bSelected;
@property (readwrite, assign) int m_iSelectedDirection;
@end
