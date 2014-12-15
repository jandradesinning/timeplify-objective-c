//
//  ViewController.m
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "ViewController.h"
#import "TrainSelectViewController.h"
#import "StationSelectViewController.h"
#import "AllSetViewController.h"
#import "FavoritesViewController.h"
#import "AboutViewController.h"
#import "GPSTestViewController.h"

#import "LeftMenuView.h"
#import "Defines.h"
#import "Utility.h"
#import "GlobalCaller.h"

#import "ST_Train.h"
#import "ST_Station.h"

@interface ViewController ()

@end

@implementation ViewController

-(void) showAbout
{
    AboutViewController* viewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    
    
    [self.navigationController pushViewController:viewController animated:YES];
    
}

-(void) showStationSelect:(int) IN_iMode
{
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    viewController.m_iScreenMode = IN_iMode;
    
    
    [self.navigationController pushViewController:viewController animated:YES];

}

-(void) showFavorites
{
    FavoritesViewController* viewController = [[FavoritesViewController alloc] initWithNibName:@"FavoritesViewController" bundle:nil];
   
    
    [self.navigationController pushViewController:viewController animated:YES];
    
}


#pragma mark LeftMenu


-(void) moveSubViewsToRight:(double) IN_dbDist
{
    for (int i= 0; i < [self.view.subviews count]; i++) {
        UIView* oV = [self.view.subviews objectAtIndex:i];
        
        CGRect oRct = oV.frame;
        oRct.origin.x += IN_dbDist;
        oV.frame = oRct;
    }
}


- (void)animationToShowLeftMenuStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
}

- (void)animationToHideLeftMenuStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
    m_LeftMenuView.hidden = YES;
    m_dbLeftNavMovedDist = 0;
}


-(void) showLeftMenu
{
    
    if (m_LeftMenuView.hidden == NO) {
        return;
    }
    
    m_LeftMenuView.hidden = NO;
    m_dbLeftNavMovedDist = INT_LEFT_NAV_MOVE_DISTANCE;
    m_LeftMenuView.m_arrNextTrains = m_arrNextTrains;
    [m_LeftMenuView setValues];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToShowLeftMenuStopped:finished:context:)];
    
    [self moveSubViewsToRight:m_dbLeftNavMovedDist];
    
    [UIView commitAnimations];
    
    
}

-(void) hideLeftMenu
{
    double dbDist = -(m_dbLeftNavMovedDist);
    
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToHideLeftMenuStopped:finished:context:)];
    
    [self moveSubViewsToRight:dbDist];
    
    [UIView commitAnimations];
    
}

-(LeftMenuView*) getLeftMenuView
{
    LeftMenuView* oView = nil;
    
    NSArray *topLevelObjects;
    
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"LeftMenuView" owner:self options:nil];
    
	for (id currentObject in topLevelObjects){
		if ([currentObject isKindOfClass:[LeftMenuView class]]){
			oView =  (LeftMenuView *) currentObject;
			break;
		}
	}
    return oView;
}



-(void)handleHideLeftMenuView:(NSNotification *)pNotification
{
    [self hideLeftMenu];
}


-(void)handleLeftMenuSelected:(NSNotification *)pNotification
{
    NSIndexPath* oInd = [pNotification object];
    if (oInd.row == 0) {
        [self showStationSelect:INT_STATION_SEL_FROM_SEE_ALL];
    }
    
    if (oInd.row == 1) {
        [self showFavorites];
    }
    
    if (oInd.row == 2) {
        [self showAbout];
    }
    
    [self hideLeftMenu];
}





#pragma mark Others



-(void) checkAndDisplayConfigScreens:(BOOL)IN_bAnimated
{
    NSArray* oArr = (NSArray*) [Utility getObjectFromDefault:STR_KEY_FAV_TRAINS];
    if (oArr != nil) {
        NSMutableArray* oArrFavTrains = [GlobalCaller getFavTrainsArray];
        [oArrFavTrains removeAllObjects];
        [oArrFavTrains addObjectsFromArray:oArr];
        return;
    }
    

    

    TrainSelectViewController* viewController = [[TrainSelectViewController alloc] initWithNibName:@"TrainSelectViewController" bundle:nil];
    
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:IN_bAnimated completion:nil];

    
    
    
    
    /*
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    viewController.m_iScreenMode = INT_STATION_SEL_FROM_WELOCOME;
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:IN_bAnimated completion:nil];
    */
    
    /*
    AllSetViewController* viewController = [[AllSetViewController alloc] initWithNibName:@"AllSetViewController" bundle:nil];
    
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:IN_bAnimated completion:nil];
     */
    
    
    /*
    FavoritesViewController* viewController = [[FavoritesViewController alloc] initWithNibName:@"FavoritesViewController" bundle:nil];
    
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:IN_bAnimated completion:nil];
     */
}






-(IBAction) btnMenuClicked:(id)sender
{
    [self showLeftMenu];
}

-(IBAction) btnGPSClicked:(id)sender
{
    
}

-(IBAction) btnMChangeDirectionClicked:(id)sender
{
    
}

-(IBAction) btnLeftArrowClicked:(id)sender
{
    
}

-(IBAction) btnRightArrowClicked:(id)sender
{
    
}

-(IBAction) btnTestGPSClicked:(id)sender
{
    GPSTestViewController* viewController = [[GPSTestViewController alloc] initWithNibName:@"GPSTestViewController" bundle:nil];
    
    
    [self.navigationController pushViewController:viewController animated:YES];

}

-(void) arrangeHideView
{
    CGRect oRct = m_ctrlViewHide.frame;
    oRct.size.height = self.view.frame.size.height - oRct.origin.y;
    oRct.size.width = self.view.frame.size.width;
    m_ctrlViewHide.frame = oRct;
    
}


-(void) viewWillAppear:(BOOL)animated
{
    
    CGRect oRct = m_LeftMenuView.frame;
    oRct.size.height = self.view.frame.size.height;
    m_LeftMenuView.frame = oRct;
    
    [self arrangeHideView];
}

-(void) getNextTrains
{
    [m_arrNextTrains removeAllObjects];
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"Data.plist" ofType:nil];
    NSDictionary* oDict = [NSDictionary dictionaryWithContentsOfFile:filepath];
    NSArray* oArr = [oDict objectForKey:@"Trains"];
    
    
    for (int i = 0; i <[oArr count]; i++) {
        NSDictionary* oDict2 = [oArr objectAtIndex:i];
        
        ST_Train* oTrain = [[ST_Train alloc] init];
        oTrain.m_iIndex = i;
        oTrain.m_strName = [oDict2 objectForKey:@"Name"];
        oTrain.m_strImage = [oDict2 objectForKey:@"Image"];
        oTrain.m_bSelected = NO;
        [m_arrNextTrains addObject:oTrain];
    }

}

-(void)handleOneAllStationSelected:(NSNotification *)pNotification
{
    ST_Station* oStation = [pNotification object];
    
    NSLog(@"handleOneAllStationSelected '%@'", oStation.m_strName);
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    m_ctrlViewHide.hidden = YES;
    
    m_arrNextTrains = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleHideLeftMenuView:)	 name:@"EVENT_HIDE_LEFT_MENU_VIEW"
												object:nil];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleLeftMenuSelected:)	 name:@"EVENT_LEFT_MENU_SELECTED"
												object:nil];
    
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleOneAllStationSelected:)	 name:@"EVENT_ONE_ALL_STATION_SELECTED"
												object:nil];


    m_LeftMenuView = [self getLeftMenuView];
    [m_LeftMenuView initControl];
    m_LeftMenuView.frame = CGRectMake(0-INT_LEFT_NAV_MOVE_DISTANCE, 0, m_LeftMenuView.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:m_LeftMenuView];
    m_LeftMenuView.hidden = YES;

    [self getNextTrains];
    
    
    [self checkAndDisplayConfigScreens:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
