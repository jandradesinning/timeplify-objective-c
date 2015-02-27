//
//  ViewController.h
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LeftMenuView;
@class Direction2View;
@class ST_Station;

@interface ViewController : UIViewController
{
    
    IBOutlet UIButton* m_ctrlBtnLeftArrow;
    IBOutlet UIButton* m_ctrlBtnRightArrow;
    IBOutlet UIButton* m_ctrlBtnSwitchDirection;
    
    
    IBOutlet UIView* m_ctrlViewHide;
    
    IBOutlet UIActivityIndicatorView* m_ctrlActivity;
    IBOutlet UIView* m_viewDim;
    
    IBOutlet UILabel* m_ctrlLblService;
    IBOutlet UILabel* m_ctrlLblDataType;
    IBOutlet UILabel* m_ctrlLblMainTimeValue;
    IBOutlet UILabel* m_ctrlLblMainTimeUnit;
    IBOutlet UILabel* m_ctrlLblNextTime;
    IBOutlet UILabel* m_ctrlLblWalkingDistance;
    IBOutlet UILabel* m_ctrlLblStation;
    IBOutlet UILabel* m_ctrlLblDirection;
    
    IBOutlet UIImageView* m_ctrlImgViewTrain;
    
    LeftMenuView* m_LeftMenuView;
    double m_dbLeftNavMovedDist;
    
    Direction2View* m_Direction2View;
    
    NSMutableArray* m_arrNextTrains;
    int m_iCurrentTrainPos;
    ST_Station* m_curStation;
    
    NSTimer* m_timerVibrate;
    int m_iVibrateCalls;
    int m_iWalkingDistance;
    
    BOOL m_bRemainingWasUp;
    
    BOOL m_bRunningMode;
    
    BOOL m_bFirstCallMade;
        
}
-(IBAction) btnMenuClicked:(id)sender;
-(IBAction) btnGPSClicked:(id)sender;
-(IBAction) btnMChangeDirectionClicked:(id)sender;
-(IBAction) btnLeftArrowClicked:(id)sender;
-(IBAction) btnRightArrowClicked:(id)sender;
-(IBAction) btnTestGPSClicked:(id)sender;
@end
