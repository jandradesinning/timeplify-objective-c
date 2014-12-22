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

@implementation FavStationCellView

@synthesize m_Station;
@synthesize m_iRowIndex;



-(void) setValues
{
    m_ctrlLblStation.text = m_Station.m_strName;

    m_ctrlLblDirection.text = @"";
    
    if (m_Station.m_iSelectedDirection == INT_DIRECTION_NORTH) {
        m_ctrlLblDirection.text = STR_DIRECTION_NORTH;
    }
    
    if (m_Station.m_iSelectedDirection == INT_DIRECTION_SOUTH) {
        m_ctrlLblDirection.text = STR_DIRECTION_SOUTH;
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
