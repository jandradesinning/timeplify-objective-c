//
//  FavTrainCellView.h
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavTrainCellView : UITableViewCell
{
    int m_iRowIndex;
    NSMutableArray* m_arrTrains;
}
-(void) setValues;
-(IBAction) btnTrainClicked:(id)sender;
@property (nonatomic, strong) NSMutableArray* m_arrTrains;
@property (readwrite, assign) int m_iRowIndex;
@end
