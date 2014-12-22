//
//  AboutViewController.h
//
//  Created by anil on 29/08/14.
//  Copyright (c) 2014 anil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController
{   
    IBOutlet UIWebView* m_ctrlWeb;
    IBOutlet UIActivityIndicatorView* m_ctrlActivity;
}
-(IBAction) btnBackClicked:(id)sender;
@end
