//
//  FavStationCellView.h
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ST_Station;

@interface FavStationCellView : UITableViewCell
{
    IBOutlet UIImageView* m_ctrlImageView;
    
    IBOutlet UILabel* m_ctrlLblStation;
    IBOutlet UILabel* m_ctrlLblDirection;
    IBOutlet UILabel* m_ctrlLblTime;
    ST_Station* m_Station;
    int m_iRowIndex;
}
-(void) setValues;
@property (nonatomic, strong) ST_Station* m_Station;
@property (readwrite, assign) int m_iRowIndex;
@end
