//
//  ST_Train.h
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ST_Train : NSObject
{
    NSString* m_strId;
    int m_iIndex;
    NSString* m_strName;
    NSString* m_strImage;
    NSString* m_strNorthStationId;
    NSString* m_strSouthStationId;
    BOOL m_bSelected;
}

@property (strong, nonatomic) NSString* m_strId;
@property (readwrite, assign) int m_iIndex;
@property (strong, nonatomic) NSString* m_strName;
@property (strong, nonatomic) NSString* m_strImage;
@property (strong, nonatomic) NSString* m_strNorthStationId;
@property (strong, nonatomic) NSString* m_strSouthStationId;
@property (readwrite, assign) BOOL m_bSelected;


@end
