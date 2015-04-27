//
//  DummyLeftRightView.m
//  Timeplify
//
//  Created by Anil on 22/04/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import "DummyLeftRightView.h"

@implementation DummyLeftRightView

@synthesize m_bLeft;

@synthesize m_ctrlImgViewTrain;
@synthesize m_ctrlLblStation;
@synthesize m_ctrlLblLastStation;
@synthesize m_ctrlLblDirection;

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
