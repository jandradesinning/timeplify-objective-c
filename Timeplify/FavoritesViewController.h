//
//  FavoritesViewController.h
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavoritesViewController : UIViewController
{
    IBOutlet UITableView* m_ctrlTblTrains;
    IBOutlet UITableView* m_ctrlTblStations;
    
    NSMutableArray* m_arrTrains;
    NSMutableArray* m_arrStations;
}

-(IBAction) btnAddClicked:(id)sender;
-(IBAction) btnBackClicked:(id)sender;
@end
