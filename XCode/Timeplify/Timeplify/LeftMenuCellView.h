//
//  LeftMenuCellView.h
//  Timeplify
//
//  Created by anil on 06/09/14.
//  Copyright (c) 2014 anil. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LeftMenuCellView : UITableViewCell
{
    IBOutlet UILabel* m_ctrlLblTime;
    IBOutlet UILabel* m_ctrlLblMenu;
    NSMutableDictionary* m_dict;
    int m_iIndex;
    IBOutlet UIImageView* m_ctrlImgView;
}
@property (strong, nonatomic) NSMutableDictionary* m_dict;
@property (readwrite, assign) int m_iIndex;
-(void) setValues;
@end
