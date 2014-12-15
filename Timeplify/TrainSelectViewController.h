//
//  TrainSelectViewController.h
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrainSelectViewController : UIViewController
{
    IBOutlet UITableView* m_ctrlTable;
    NSMutableArray* m_arrRecords;
}
-(IBAction) btnNextClicked:(id)sender;
@end
