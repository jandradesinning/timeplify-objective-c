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
    int m_iId;
    int m_iIndex;
    NSString* m_strName;
    NSString* m_strImage;
    BOOL m_bSelected;
}

@property (readwrite, assign) int m_iId;
@property (readwrite, assign) int m_iIndex;
@property (strong, nonatomic) NSString* m_strName;
@property (strong, nonatomic) NSString* m_strImage;
@property (readwrite, assign) BOOL m_bSelected;


@end
