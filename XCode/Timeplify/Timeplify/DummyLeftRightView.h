//
//  DummyLeftRightView.h
//  Timeplify
//
//  Created by Anil on 22/04/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DummyLeftRightView : UIView
{
    IBOutlet UIImageView* m_ctrlImgViewTrain;
    IBOutlet UILabel* m_ctrlLblStation;
    IBOutlet UILabel* m_ctrlLblLastStation;
    IBOutlet UILabel* m_ctrlLblDirection;
    
    BOOL m_bLeft;
}
@property (nonatomic, strong)   IBOutlet UIImageView* m_ctrlImgViewTrain;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblStation;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblLastStation;
@property (nonatomic, strong)   IBOutlet UILabel* m_ctrlLblDirection;

@property (readwrite, assign)   BOOL m_bLeft;
@end
