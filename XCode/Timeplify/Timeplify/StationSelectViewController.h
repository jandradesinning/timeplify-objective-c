//
//  StationSelectViewController.h
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FlowCoverView.h"

@class DirectionView;

@interface StationSelectViewController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, FlowCoverViewDelegate>
{
    IBOutlet UILabel* m_ctrlLblTitle;
    
    IBOutlet UIButton* m_ctrlBtnBack;
    IBOutlet UIButton* m_ctrlBtnNext;
    IBOutlet UIButton* m_ctrlBtnDone;
    
    IBOutlet UIActivityIndicatorView* m_ctrlActivity;
    
    NSMutableArray* m_arrTrains;
    
    NSMutableArray* m_arrAllValues;
    NSMutableArray *m_arrSearchValues;
    
    IBOutlet FlowCoverView* m_ctrlFlowCover;
    IBOutlet UITableView* m_ctrlTable;
    UISearchDisplayController *m_searchDisplayController;
    IBOutlet UISearchBar * m_ctrlSearchBar;
    

    DirectionView* m_DirectionView;
    int m_iScreenMode;
    
    int m_iTrainIndex;

}
@property (readwrite, assign) int m_iScreenMode;
@property (readwrite, assign) int m_iTrainIndex;
-(void) updateVisibleCells:(UITableView*)IN_TableView;
-(IBAction) btnDoneClicked:(id)sender;
-(IBAction) btnNextClicked:(id)sender;
-(IBAction) btnBackClicked:(id)sender;
@end
