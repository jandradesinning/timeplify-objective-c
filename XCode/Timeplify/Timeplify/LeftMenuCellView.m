//
//  LeftMenuCellView.m
//  Timeplify
//
//  Created by anil on 06/09/14.
//  Copyright (c) 2014 anil. All rights reserved.
//

#import "LeftMenuCellView.h"
#import "StatusUtility.h"

@implementation LeftMenuCellView

@synthesize m_dict;
@synthesize m_iIndex;


-(void) setValues
{
   
    if (m_dict == nil) {
        
        m_ctrlImgView.hidden = YES;
        m_ctrlLblTime.hidden = YES;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        
        CGRect oRect = m_ctrlLblMenu.frame;
        oRect.origin.x = 15;
        m_ctrlLblMenu.frame = oRect;
        
        m_ctrlLblMenu.font = [UIFont boldSystemFontOfSize:17.0];
        
        if (m_iIndex == 0) {
            m_ctrlLblMenu.text = @"See All Stations";
        }
        if (m_iIndex == 1) {
            m_ctrlLblMenu.text = @"Favorites";
        }
        if (m_iIndex == 2) {
            m_ctrlLblMenu.text = @"About This App";
        }
        if (m_iIndex == 3) {
            m_ctrlLblMenu.text = @"Rate This App";
        }
        
        
        return;
    }
    
    
    m_ctrlLblMenu.font = [UIFont systemFontOfSize:15.0];
    
    NSLog(@"m_dict '%@'", m_dict);
    
    CGRect oRect = m_ctrlLblMenu.frame;
    oRect.origin.x = 45;
    m_ctrlLblMenu.frame = oRect;
    
    m_ctrlLblMenu.text = [m_dict objectForKey:@"LAST_STATION"];;
    
    m_ctrlImgView.hidden = NO;
    m_ctrlLblTime.hidden = NO;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.selectionStyle = UITableViewCellSelectionStyleNone;


    
    
    NSString* strRoute = [m_dict objectForKey:@"routeId"];
    if (strRoute != nil) {
        NSString* strNormalImage = [NSString stringWithFormat:@"vehicle-logo-%@.png", strRoute];
        
        strNormalImage = [strNormalImage lowercaseString];
        m_ctrlImgView.image = [UIImage imageNamed:strNormalImage];;
    }
    
    StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
    NSString* strTime = [oStatusUtil getTimeRemaining:m_dict];
    m_ctrlLblTime.text = strTime;
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
