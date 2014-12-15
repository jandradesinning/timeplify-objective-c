//
//  StationSelectCellView.h
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ST_Station;

@interface StationSelectCellView : UITableViewCell
{
    IBOutlet UIImageView* m_ctrlImgViewStar;
    IBOutlet UILabel* m_ctrlLblStation;
    IBOutlet UILabel* m_ctrlLblDirection;
    ST_Station* m_Station;
    int m_iRowIndex;
    int m_iScreenMode;
}
-(void) setValues;
@property (nonatomic, strong) ST_Station* m_Station;
@property (readwrite, assign) int m_iRowIndex;
@property (readwrite, assign) int m_iScreenMode;
@end
