//
//  FavoritesViewController.h
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FavoritesViewController : UIViewController
{
    IBOutlet UITableView* m_ctrlTblStations;

    NSMutableArray* m_arrStations;
    
    IBOutlet UIActivityIndicatorView* m_ctrlActivity;
    
    CLLocationCoordinate2D m_curGPS;
}

-(IBAction) btnAddClicked:(id)sender;
-(IBAction) btnBackClicked:(id)sender;
@end
