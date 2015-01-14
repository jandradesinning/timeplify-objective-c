//
//  Direction2View.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "Direction2View.h"
#import "ST_Station.h"
#import "Defines.h"

@implementation Direction2View

@synthesize m_Station;



-(void) doClose
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_DIRECTION_2_SELECTED" object:self];
}


-(void) setValues
{
    m_ctrlLblTitle.text = m_Station.m_strStationName;
    [m_ctrlBtnNorth setTitle:m_Station.m_strNorthDirection forState:UIControlStateNormal];
    [m_ctrlBtnSouth setTitle:m_Station.m_strSouthDirection forState:UIControlStateNormal];
}

-(void) initCtrl
{
    m_WhiteView.layer.cornerRadius = 5.0;
}

-(IBAction) btnNorthClicked:(id)sender
{
    m_Station.m_iSelectedDirection = INT_DIRECTION_NORTH;
    [self doClose];
}
-(IBAction) btnSouthClicked:(id)sender
{
    m_Station.m_iSelectedDirection = INT_DIRECTION_SOUTH;
    [self doClose];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
