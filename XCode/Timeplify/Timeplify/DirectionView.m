//
//  DirectionView.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "DirectionView.h"
#import "ST_Station.h"
#import "Defines.h"
#import "GlobalCaller.h"

@implementation DirectionView

@synthesize m_Station;



-(void) doClose
{
    [GlobalCaller updateFavStation:m_Station];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_HIDE_DIRECTION_VIEW" object:self];
}


-(void) setValues
{
    m_ctrlLblTitle.text = m_Station.m_strName;
    [m_ctrlBtnNorth setTitle:m_Station.m_strNorthDirection forState:UIControlStateNormal];
    [m_ctrlBtnSouth setTitle:m_Station.m_strSouthDirection forState:UIControlStateNormal];
}

-(void) initCtrl
{
    
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
-(IBAction) btnEitherClicked:(id)sender
{
    m_Station.m_iSelectedDirection = INT_DIRECTION_EITHER;
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
