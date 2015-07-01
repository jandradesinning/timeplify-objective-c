//
//  CheckWebStatus.h
//  Timeplify
//
//  Created by Jose Andrade-Sinning on 6/30/15.
//  Copyright (c) 2015 Timeplify, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckWebStatus : UIViewController
{
    IBOutlet UIWebView* m_ctrlWeb;
    IBOutlet UIActivityIndicatorView* m_ctrlActivity;
}

- (IBAction)btnBackClicked:(id)sender;

@end
