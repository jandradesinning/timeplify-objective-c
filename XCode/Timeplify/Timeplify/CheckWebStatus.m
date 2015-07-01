//
//  CheckWebStatus.m
//  Timeplify
//
//  Created by Jose Andrade-Sinning on 6/30/15.
//  Copyright (c) 2015 Timeplify, LLC. All rights reserved.
//

#import "CheckWebStatus.h"

@interface CheckWebStatus ()

@end

@implementation CheckWebStatus

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

- (IBAction)btnBackClicked:(id)sender {
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
    
    //NSString *filepath = [[NSBundle mainBundle] pathForResource:@"About.html" ofType:nil];
    //NSURL *url = [NSURL fileURLWithPath:filepath];
    NSURL *url = [NSURL URLWithString:@"http://m.mta.info/mt/www.mta.info?un_jtt_redirect=un_jtt_iosV"];
    [m_ctrlWeb loadRequest:[NSURLRequest requestWithURL:url]];
    
    m_ctrlActivity.hidden = YES;
    
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
