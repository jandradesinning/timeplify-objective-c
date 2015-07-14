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
@class PullDownRefreshScrollView;
@class DummyLeftRightView;

@interface ViewController : UIViewController
{
    
    IBOutlet PullDownRefreshScrollView *m_ctrlPullDownScrollView;
    
    IBOutlet UIButton* m_ctrlBtnSwitchDirection;
    
    
    IBOutlet UIView* m_ctrlViewHide;
    
    IBOutlet UIActivityIndicatorView* m_ctrlActivity;
    IBOutlet UIView* m_viewDim;
    
    IBOutlet UILabel* m_ctrlLblNoInternet;
    IBOutlet UILabel* m_ctrlLblService;
    IBOutlet UILabel* m_ctrlLblDataType;
    IBOutlet UILabel* m_ctrlLblMainTimeValue;
    IBOutlet UILabel* m_ctrlLblMainTimeUnit;
    IBOutlet UILabel* m_ctrlLblNextTime;
    IBOutlet UILabel* m_ctrlLblWalkingDistance;
    IBOutlet UILabel* m_ctrlLblStation;
    IBOutlet UILabel* m_ctrlLblLastStation;
    IBOutlet UILabel* m_ctrlLblDirection;
    
    IBOutlet UIImageView* m_ctrlImgViewTrain;
    IBOutlet UIImageView* m_ctrlImgJustLeft;
    
    LeftMenuView* m_LeftMenuView;
    double m_dbLeftNavMovedDist;
    
    Direction2View* m_Direction2View;
    
    NSMutableArray* m_arrNextTrains;
    int m_iCurrentFavOnlyTrainPos;
    int m_iCurrentNextFavOnlyTrainPos;
    ST_Station* m_curStation;
    
    NSTimer* m_timerVibrate;
    NSTimer* m_timerJustLeft;
    
    int m_iVibrateCalls;
    int m_iWalkingDistance;
    
    int m_iJustLeftCalls;
    
    BOOL m_bRemainingWasUp;
    
    BOOL m_bRunningMode;
    
    BOOL m_bFirstCallMade;
    
    BOOL m_bDataTypeBlink;
    
    
    DummyLeftRightView* m_DummyLeftView;
    DummyLeftRightView* m_DummyRightView;
    
    
    ViewController* m_VCFlipParent;
    BOOL m_bDummyFlip;
    
    double m_dbOffSetPrevious;
}

@property (readwrite, assign)   BOOL m_bDummyFlip;
@property (nonatomic, strong)   ViewController* m_VCFlipParent;

@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblNoInternet;
@property (nonatomic, strong)   IBOutlet UIButton* m_ctrlBtnLeftArrow;
@property (nonatomic, strong)   IBOutlet UIButton* m_ctrlBtnRightArrow;
@property (nonatomic, strong)   IBOutlet UIButton* m_ctrlBtnSwitchDirection;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblService;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblDataType;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblMainTimeValue;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblMainTimeUnit;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblNextTime;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblWalkingDistance;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblStation;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblDirection;
@property (nonatomic, strong)   IBOutlet UIImageView* m_ctrlImgViewTrain;
@property (nonatomic, strong)   IBOutlet UIImageView* m_ctrlImgJustLeft;

-(IBAction) btnMenuClicked:(id)sender;
-(IBAction) btnGPSClicked:(id)sender;
-(IBAction) btnFavoriteClicked:(id)sender;
-(IBAction) btnSubwayClicked:(id)sender;
-(IBAction) btnMChangeDirectionClicked:(id)sender;
-(IBAction) btnTestGPSClicked:(id)sender;


-(void) goToLeftScreen;
-(void) goToRightScreen;
-(void) getNearestStation;
-(void) setFlipControllerValues;

@end
