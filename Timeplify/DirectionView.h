//
//  DirectionView.h
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ST_Station;

@interface DirectionView : UIView
{
    IBOutlet UILabel* m_ctrlLblTitle;
    
    IBOutlet UIButton* m_ctrlBtnNorth;
    IBOutlet UIButton* m_ctrlBtnSouth;
    IBOutlet UIButton* m_ctrlBtnEither;
    ST_Station* m_Station;
}
@property (nonatomic, strong) ST_Station* m_Station;
-(IBAction) btnNorthClicked:(id)sender;
-(IBAction) btnSouthClicked:(id)sender;
-(IBAction) btnEitherClicked:(id)sender;
-(void) setValues;
-(void) initCtrl;
@end
