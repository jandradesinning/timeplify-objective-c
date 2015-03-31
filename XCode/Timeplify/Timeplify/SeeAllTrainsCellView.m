//
//  SeeAllTrainsCellView.m
//  Timeplify
//
//  Created by Anil on 25/03/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import "SeeAllTrainsCellView.h"
#import "Defines.h"
#import "ST_Train.h"

@implementation SeeAllTrainsCellView

@synthesize m_arrTrains;

@synthesize m_iRowIndex;

-(UIButton*) getBtnWithTag:(int)IN_iTag
{
    for (int i = 0; i <[self.subviews count]; i++) {
        UIView* oBtn = [self.subviews objectAtIndex:i];
        if ([oBtn isKindOfClass:[UIButton class]]) {
            if (oBtn.tag == IN_iTag) {
                return (UIButton*)oBtn;
            }
            continue;
        }
        
        
        for (int j = 0; j <[oBtn.subviews count]; j++) {
            UIView* oBtn2 = [oBtn.subviews objectAtIndex:j];
            if ([oBtn2 isKindOfClass:[UIButton class]]) {
                if (oBtn2.tag == IN_iTag) {
                    return (UIButton*)oBtn2;
                }
                continue;
            }
            
            
            for (int k = 0; k <[oBtn2.subviews count]; k++) {
                UIView* oBtn3 = [oBtn2.subviews objectAtIndex:k];
                if ([oBtn3 isKindOfClass:[UIButton class]]) {
                    if (oBtn3.tag == IN_iTag) {
                        return (UIButton*)oBtn3;
                    }
                    continue;
                }
            }
            
        }
        
        
    }
    
    return nil;
}

-(void) setValues
{
    for (int i=0; i < INT_WELCOME_TRAINS_IN_A_ROW; i++) {
        
        UIButton* oBtn = [self getBtnWithTag:(i+1)];
        if (oBtn == nil) {
            continue;
        }
        
        int iIndex = (m_iRowIndex * INT_WELCOME_TRAINS_IN_A_ROW) + i;
        
        if (iIndex >= [m_arrTrains count]) {
            oBtn.hidden = YES;
            continue;
        }
        oBtn.hidden = NO;
        
        ST_Train* oTrain = [m_arrTrains objectAtIndex:iIndex];
        
        
        NSString* strNormalImage = [NSString stringWithFormat:@"vehicle-logo-%@.png", oTrain.m_strImage];
        
        NSLog(@"Image '%@'", strNormalImage);
        
        strNormalImage = [strNormalImage lowercaseString];

        [oBtn setBackgroundImage:[UIImage imageNamed:strNormalImage] forState:UIControlStateNormal];
    }
    
}



-(IBAction) btnTrainClicked:(id)sender
{
    int iTag = (int) ((UIButton*)sender).tag;
    if (iTag < 1) {
        return;
    }
    if (iTag > INT_WELCOME_TRAINS_IN_A_ROW) {
        return;
    }
    int iPos = iTag -1;
    
    int iIndex = (m_iRowIndex * INT_WELCOME_TRAINS_IN_A_ROW) + iPos;
    
    NSNumber* oNum = [NSNumber numberWithInt:iIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_SEE_ALL_TRAIN_SELECTED" object:oNum];
}


- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
