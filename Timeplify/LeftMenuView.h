//
//  LeftMenuView.h
//  Timeplify
//
//  Created by anil on 06/09/14.
//  Copyright (c) 2014 anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeftMenuView : UIView
{
    IBOutlet UITableView* m_ctrlTable;
    NSMutableArray* m_arrNextTrains;

}
-(void) setValues;
@property (nonatomic, strong) NSMutableArray* m_arrNextTrains;
-(void) initControl;
@end
