//
//  LeftMenuCellView.h
//  Timeplify
//
//  Created by anil on 06/09/14.
//  Copyright (c) 2014 anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ST_Train;

@interface LeftMenuCellView : UITableViewCell
{
    IBOutlet UILabel* m_ctrlLblTime;
    IBOutlet UILabel* m_ctrlLblMenu;
    ST_Train* m_Train;
    int m_iIndex;
    IBOutlet UIImageView* m_ctrlImgView;
}
@property (strong, nonatomic) ST_Train* m_Train;
@property (readwrite, assign) int m_iIndex;
-(void) setValues;
@end
