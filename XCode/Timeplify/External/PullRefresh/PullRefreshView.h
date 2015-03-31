//
//  PullRefreshView.h
//  Timeplify
//
//  Created by Anil on 22/03/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PullRefreshView : UIView
{
    IBOutlet UIImageView *refreshArrow;
    IBOutlet UIActivityIndicatorView *refreshLoadingIcon;
}
@property (nonatomic, strong) IBOutlet UIImageView *refreshArrow;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *refreshLoadingIcon;
@end
