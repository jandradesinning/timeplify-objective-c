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
    IBOutlet UIButton* m_ctrlBtnNext;
    IBOutlet UITableView* m_ctrlTable;
    IBOutlet UIActivityIndicatorView* m_ctrlActivity;
    NSMutableArray* m_arrRecords;
}
-(IBAction) btnNextClicked:(id)sender;
-(void) getServerAppSettings;
@end
