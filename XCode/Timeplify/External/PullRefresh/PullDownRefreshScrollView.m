//
//  PullDownRefreshScrollView.m
//  bbbbb
//
//  Created by James on 11/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PullDownRefreshScrollView.h"
#import "PullRefreshView.h"

#import <QuartzCore/CALayer.h>

@implementation PullDownRefreshScrollView


-(PullRefreshView*) getPullRefreshView
{
    PullRefreshView* oView = nil;
    
    NSArray *topLevelObjects;
    
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"PullRefreshView" owner:self options:nil];
    
	for (id currentObject in topLevelObjects){
		if ([currentObject isKindOfClass:[PullRefreshView class]]){
			oView =  (PullRefreshView *) currentObject;
			break;
		}
	}
    return oView;
}


- (void) initPushLoadingView
{
    [self setDelegate:self];
    
    refreshView = [self getPullRefreshView];
    
    CGRect oRct =refreshView.frame;
    oRct.origin.y -= REFHEIGHT;
    refreshView.frame = oRct;

    
    [self addSubview:refreshView];
    
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    isLoading = false;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isDraging = true;
}

-(void)scrollViewDidScroll:(UIScrollView *)myscrollView
{
    
    
    if(!isLoading)
    {
        if (isDraging && myscrollView.contentOffset.y < 0 - REFHEIGHT)
        {
            [UIView animateWithDuration:0.25 animations:^{
                CALayer *layer = refreshView.refreshArrow.layer;
                layer.transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
            }];
        }
        else
        {
            [UIView animateWithDuration:0.25 animations:^{
                [refreshView.refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
            }];
        }
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)myscrollView willDecelerate:(BOOL)decelerate
{
     
    if ((myscrollView.contentOffset.y > -50) &&(myscrollView.contentOffset.y < 50)) {
        if (myscrollView.contentOffset.x > 50) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_SWIPED_MAIN_VIEW" object:@"LEFT"];
        }
        
        if (myscrollView.contentOffset.x < -50)  {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_SWIPED_MAIN_VIEW" object:@"RIGHT"];
        }
    }
    

    
    
    
    isDraging = false;
    if (myscrollView.contentOffset.y < 0 - REFHEIGHT)
    {
        
        [UIView animateWithDuration:0.5 animations:^{
            self.contentInset = UIEdgeInsetsMake(REFHEIGHT, 0, 0, 0);
        }];
        
        isLoading = true;
        
        [refreshView.refreshLoadingIcon startAnimating];
        [refreshView.refreshArrow setHidden:YES];
        
        [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0.5];
    }
}

- (void)stopLoading
{
    isLoading = false;
    [refreshView.refreshLoadingIcon stopAnimating];
    [refreshView.refreshArrow setHidden:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_PULLED_TO_REFRESH" object:nil];
    
    // Hide the header
    [UIView animateWithDuration:0.3 animations:^{
        self.contentInset = UIEdgeInsetsZero;
    }
                     completion:^(BOOL finished) {
                         [self performSelector:@selector(stopLoadingComplete)];
                     }];
}

- (void)stopLoadingComplete
{
    NSLog(@"stopLoadingComplete");
    
}
@end
