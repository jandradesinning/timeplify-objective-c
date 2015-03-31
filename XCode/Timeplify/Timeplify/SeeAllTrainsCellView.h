//
//  SeeAllTrainsCellView.h
//  Timeplify
//
//  Created by Anil on 25/03/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SeeAllTrainsCellView : UITableViewCell
{
    int m_iRowIndex;
    NSMutableArray* m_arrTrains;
}
-(void) setValues;
-(IBAction) btnTrainClicked:(id)sender;
@property (nonatomic, strong) NSMutableArray* m_arrTrains;
@property (readwrite, assign) int m_iRowIndex;

@end
