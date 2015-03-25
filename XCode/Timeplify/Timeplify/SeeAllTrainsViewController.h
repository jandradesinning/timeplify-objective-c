//
//  SeeAllTrainsViewController.h
//  Timeplify
//
//  Created by Anil on 25/03/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SeeAllTrainsViewController : UIViewController
{
    IBOutlet UITableView* m_ctrlTable;
    NSMutableArray* m_arrRecords;
}
-(IBAction) btnBackClicked:(id)sender;
@end
