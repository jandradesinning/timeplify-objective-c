//
//  AboutViewController.m
//
//  Created by anil on 29/08/14.
//  Copyright (c) 2014 anil. All rights reserved.
//

#import "AboutViewController.h"


@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [m_ctrlActivity startAnimating];
    m_ctrlActivity.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    m_ctrlActivity.hidden = YES;
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(IBAction) btnBackClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [m_ctrlActivity startAnimating];
    m_ctrlActivity.hidden = NO;
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"About.html" ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:filepath];
    [m_ctrlWeb loadRequest:[NSURLRequest requestWithURL:url]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) dealloc
{
    [m_ctrlWeb stopLoading];
    m_ctrlWeb.delegate = nil;
}
@end