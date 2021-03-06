//
//  GPSTestViewController.m
//  Timeplify
//
//  Created by Anil on 13/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "GPSTestViewController.h"
#import "AppDelegate.h"
#import "Defines.h"

@interface GPSTestViewController ()

@end

@implementation GPSTestViewController

-(void) setTitleLabel
{
    AppDelegate* appDel= (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSString* strTxt = [NSString stringWithFormat:@"GPS (%0.6lf, %0.6lf)",
                        appDel.m_GPSCoordinate.latitude,
                        appDel.m_GPSCoordinate.longitude];
    m_ctrlLblTitle.text = strTxt;
}

-(IBAction) btnBackClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)mapView:(MKMapView *)mapView
                regionDidChangeAnimated:(BOOL)animated
{
    AppDelegate* appDel= (AppDelegate*) [[UIApplication sharedApplication] delegate];
    appDel.m_GPSCoordinate = mapView.centerCoordinate;
    
    [self setTitleLabel];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_SIGNIFICANT_GPS_CHANGE" object:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(IBAction) btnDefClicked:(id)sender
{
    CLLocationCoordinate2D oLoc = CLLocationCoordinate2DMake(INT_TESTING_LATITUDE, INT_TESTING_LONGITUDE);
    AppDelegate* appDel= (AppDelegate*) [[UIApplication sharedApplication] delegate];
    appDel.m_GPSCoordinate = oLoc;
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(appDel.m_GPSCoordinate, 1000, 1000);
    [m_ctrlMap setRegion:region animated:YES];
    
    [self setTitleLabel];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_SIGNIFICANT_GPS_CHANGE" object:nil];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    AppDelegate* appDel= (AppDelegate*) [[UIApplication sharedApplication] delegate];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(appDel.m_GPSCoordinate, 1000, 1000);
    [m_ctrlMap setRegion:region animated:YES];
    
    [self setTitleLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
