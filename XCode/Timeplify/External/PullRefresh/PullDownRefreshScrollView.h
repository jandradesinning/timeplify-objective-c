//
//  PullDownRefreshScrollView.h
//  bbbbb
//
//  Created by James on 11/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define REFHEIGHT   60

@class PullRefreshView;


@interface PullDownRefreshScrollView : UIScrollView <UIScrollViewDelegate>
{
    

    PullRefreshView  *refreshView;
    
    Boolean isLoading;
    Boolean isDraging;
}
@property (nonatomic, strong) PullRefreshView  *refreshView;

-(void)initPushLoadingView;

@end
