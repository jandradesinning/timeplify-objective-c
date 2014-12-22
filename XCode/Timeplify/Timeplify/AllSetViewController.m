//
//  AllSetViewController.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "AllSetViewController.h"
#import "GlobalCaller.h"
#import "Utility.h"
#import "Defines.h"

@interface AllSetViewController ()

@end

@implementation AllSetViewController

-(IBAction) btnCheckTimesClicked:(id)sender
{
    NSMutableArray* oArr = [GlobalCaller getFavTrainsArray];
    [Utility saveObjectInDefault:STR_KEY_FAV_TRAINS :oArr];
    
    NSMutableArray* oArr2 = [GlobalCaller getFavStationsArray];
    [Utility saveObjectInDefault:STR_KEY_FAV_STATIONS :oArr2];
    
    
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
