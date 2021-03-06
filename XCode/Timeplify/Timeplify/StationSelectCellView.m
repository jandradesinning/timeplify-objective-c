//
//  StationSelectCellView.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "StationSelectCellView.h"
#import "ST_Station.h"
#import "Defines.h"

@implementation StationSelectCellView

@synthesize m_Station;
@synthesize m_iRowIndex;
@synthesize m_iScreenMode;

-(void) setValues
{
    m_ctrlLblStation.text = m_Station.m_strStationName;
    
    m_ctrlImgViewStar.image = [UIImage imageNamed:@"favorties-star-clear.png"];
    m_ctrlLblDirection.text = @"";
    
    
    self.accessoryType = UITableViewCellAccessoryNone;
    m_ctrlImgViewStar.hidden = NO;
    m_ctrlLblDirection.hidden = NO;
    
    
    BOOL bFav = NO;
    
    if (m_Station.m_iSelectedDirection == INT_DIRECTION_NORTH) {
        m_ctrlImgViewStar.image = [UIImage imageNamed:@"favorites-star-filled.png"];
        m_ctrlLblDirection.text = STR_DIRECTION_NORTH;
        bFav = YES;
    }
    
    if (m_Station.m_iSelectedDirection == INT_DIRECTION_SOUTH) {
        m_ctrlImgViewStar.image = [UIImage imageNamed:@"favorites-star-filled.png"];
        m_ctrlLblDirection.text = STR_DIRECTION_SOUTH;
        bFav = YES;
    }
    
    if (m_Station.m_iSelectedDirection == INT_DIRECTION_EITHER) {
        m_ctrlImgViewStar.image = [UIImage imageNamed:@"favorites-star-filled.png"];
        m_ctrlLblDirection.text = STR_DIRECTION_EITHER;
        bFav = YES;
    }
    
    if (m_iScreenMode == INT_STATION_SEL_FROM_SEE_ALL) {
        if (bFav == YES) {
            self.accessoryType = UITableViewCellAccessoryNone;
        }
        else
        {
            m_ctrlImgViewStar.hidden = YES;
            m_ctrlLblDirection.hidden = YES;
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
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
