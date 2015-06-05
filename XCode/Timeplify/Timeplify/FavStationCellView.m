//
//  FavStationCellView.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "FavStationCellView.h"
#import "ST_Station.h"
#import "Defines.h"
#import "StatusUtility.h"

@implementation FavStationCellView

@synthesize m_Station;
@synthesize m_iRowIndex;



-(void) setValues
{
    m_ctrlLblStation.text = m_Station.m_strStationName;

    m_ctrlLblDirection.text = @"";
    
    
    
    NSString* strNormalImage = [NSString stringWithFormat:@"vehicle-logo-%@.png", m_Station.m_strRouteId];
    strNormalImage = [strNormalImage lowercaseString];
    m_ctrlImageView.image = [UIImage imageNamed:strNormalImage];
    
    /*
    m_ctrlLblTime.text = @"";
    if (m_Station.m_dbWalkingDistance >=0 ) {
        StatusUtility* oStat = [[StatusUtility alloc] init];
        NSString* strTime = [oStat getFormattedSeconds:m_Station.m_dbWalkingDistance];
        m_ctrlLblTime.text = strTime;
    }
    */
    
    double dbTime = m_Station.m_dbNextTrainTime;
    if (dbTime < 1) {
        dbTime = 1;
    }
    
    NSString* strTime = [NSString stringWithFormat:@"%0.0lf min", dbTime];
    m_ctrlLblTime.text = strTime;
     
    
    if (m_Station.m_iSelectedDirection == INT_DIRECTION_NORTH) {
        m_ctrlLblDirection.text = m_Station.m_strNorthDirection;  //STR_DIRECTION_NORTH;
    }
    
    if (m_Station.m_iSelectedDirection == INT_DIRECTION_SOUTH) {
        m_ctrlLblDirection.text = m_Station.m_strSouthDirection; //STR_DIRECTION_SOUTH;
    }
    
    if (m_Station.m_iSelectedDirection == INT_DIRECTION_EITHER) {
        m_ctrlLblDirection.text = STR_DIRECTION_EITHER;
    }
    
}


- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
