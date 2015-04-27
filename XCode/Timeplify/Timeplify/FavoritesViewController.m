//
//  FavoritesViewController.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "FavoritesViewController.h"
#import "FavStationCellView.h"

#import "Defines.h"
#import "ST_Train.h"
#import "ST_Station.h"
#import "GlobalCaller.h"
#import "StationSelectViewController.h"
#import "Utility.h"

#import "TrainSelectViewController.h"

#import "AppDelegate.h"
#import "StatusUtility.h"

@interface FavoritesViewController ()

@end

@implementation FavoritesViewController


-(void) deleteRowAtIndex:(NSIndexPath*) IN_oIndx
{
    if (IN_oIndx.row >= [m_arrStations count]) {
        return;
    }
    
    
    ST_Station* oStation = [m_arrStations objectAtIndex:(int)IN_oIndx.row];
    oStation.m_iSelectedDirection = 0;
    [GlobalCaller updateFavStation:oStation];
    
    [m_arrStations removeObjectAtIndex:IN_oIndx.row];
    

    NSArray* oArr = [NSArray arrayWithObject:IN_oIndx];
    [m_ctrlTblStations deleteRowsAtIndexPaths:oArr withRowAnimation:UITableViewRowAnimationTop];
 
}

#pragma mark Table


-(FavStationCellView*) getFavStationCellView:(UITableView *)tableView
{
    NSString *CellIdentifier = @"FavStationCellView";
    
    FavStationCellView *cell = (FavStationCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"FavStationCellView" owner:self options:nil];
        
        for (id currentObject in topLevelObjects)
        {
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell =  (FavStationCellView *) currentObject;
                break;
            }
        }
        
    }
    
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (m_bProcessingOver == NO) {
        return 0;
    }
    
    return [m_arrStations count];
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
    
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavStationCellView* cell = [self getFavStationCellView:tableView];
    
    ST_Station* oStation = [m_arrStations objectAtIndex:(int)indexPath.row];
    
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    if (appDel.m_iGPSStatus != 2)
    {
        oStation.m_dbWalkingDistance = -1;
    }
        
    
    
    cell.m_iRowIndex = (int) indexPath.row;
    cell.m_Station = oStation;
    [cell setValues];
    
    return cell;

}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    ST_Station* oStation = [m_arrStations objectAtIndex:(int)indexPath.row];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_FAV_STATION_SELECTED" object:oStation];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        [self performSelector:@selector(deleteRowAtIndex:) withObject:indexPath afterDelay:0.0];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(void) getStations
{
    [m_arrStations removeAllObjects];
    
    NSMutableArray* oArrFavStations = [GlobalCaller getFavStationsArray];
    for (int i = 0; i <[oArrFavStations count]; i++) {
        ST_Station* oStation = [oArrFavStations objectAtIndex:i];
        oStation.m_iIndex = i;
        [m_arrStations addObject:oStation];
    }
    
}

-(IBAction) btnBackClicked:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    NSMutableArray* oArr = [GlobalCaller getFavTrainsArray];
    [Utility saveObjectInDefault:STR_KEY_FAV_TRAINS :oArr];
    
    NSMutableArray* oArr2 = [GlobalCaller getFavStationsArray];
    [Utility saveObjectInDefault:STR_KEY_FAV_STATIONS :oArr2];

    
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction) btnAddClicked:(id)sender
{
    
    TrainSelectViewController* viewController = [[TrainSelectViewController alloc] initWithNibName:@"TrainSelectViewController" bundle:nil];
    
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    
   
}




#pragma mark Distance Sort


NSInteger sortStationComparer2(id num1, id num2, void *context)
{
	// Sort Function
	ST_Station* oStation1 = (ST_Station*)num1;
	ST_Station* oStation2 = (ST_Station*)num2;
	
	
	return (oStation1.m_dbWalkingDistance > oStation2.m_dbWalkingDistance);
}


-(void) sortAllStations{
    
    NSMutableArray* oArrStations = m_arrStations;
    
  
    [oArrStations sortUsingFunction:sortStationComparer2 context:(__bridge void *)(self)];
    
}


#pragma mark Walking Distance

-(void) mainThreadAfterWalkingDistance:(ST_Station*)IN_stStation
{
    BOOL bOk = YES;
    for (int i = 0; i < [m_arrStations count]; i++)
	{
		ST_Station* oStation = (ST_Station*) [m_arrStations objectAtIndex:i];
        
        if  (oStation.m_dbWalkingDistance < -100)
        {
            bOk = NO;
            break;
        }
	}
    
    if (bOk == YES) {
        
        [self sortAllStations];
        NSLog(@"Ok");
        m_bProcessingOver = YES;
        m_ctrlActivity.hidden = YES;
        [m_ctrlTblStations reloadData];
    }
}

-(void) getWalkingDistanceInBackground:(ST_Station*)IN_stStation
{
    
    ST_Station* oStation = IN_stStation;
    
    NSString *strURL = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/distancematrix/json?origins=%f,%f&destinations=%f,%f&mode=walking&language=en-EN&sensor=false",
                        m_curGPS.latitude,
                        m_curGPS.longitude,
                        oStation.m_dbLatitude, oStation.m_dbLongitude];
    
    NSData *locData = [NSData dataWithContentsOfURL:[NSURL URLWithString:strURL]];
    
    if (locData != nil) {
        NSDictionary *locDict = [NSJSONSerialization JSONObjectWithData:locData options:kNilOptions error:nil];
        if (locDict != nil) {
            StatusUtility* oStatusUtil = [[StatusUtility alloc] init];
            oStation.m_dbWalkingDistance = [oStatusUtil getWalkingDistanceInSecs:locDict];
        }
        else
        {
            oStation.m_dbWalkingDistance = -1;
        }
    }
    else
    {
        oStation.m_dbWalkingDistance = -1;
    }
    
    
        
    [self performSelectorOnMainThread:@selector(mainThreadAfterWalkingDistance:) withObject:oStation waitUntilDone:YES];
    
	CFRunLoopRun();
    
}

-(void) getWalkingDistances
{
    
    
    for (int i = 0; i < [m_arrStations count]; i++)
	{
		ST_Station* oStation = (ST_Station*) [m_arrStations objectAtIndex:i];
        
        oStation.m_dbWalkingDistance = -101;
        [self performSelectorInBackground:@selector(getWalkingDistanceInBackground:) withObject:oStation];
        
	}
}



-(void) prepareStationList
{
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    m_curGPS = appDel.m_GPSCoordinate;
    
    [self getStations];
    
    if (appDel.m_iGPSStatus != 2)
    {
        m_bProcessingOver = YES;
        m_ctrlActivity.hidden = YES;
        [m_ctrlTblStations reloadData];
        return;
    }
    
    if ([m_arrStations count] < 1) {
        m_bProcessingOver = YES;
        m_ctrlActivity.hidden = YES;
        [m_ctrlTblStations reloadData];
        return;

    }
    
    [self getWalkingDistances];
}

#pragma mark Others


-(void)handleReloadFavorites:(NSNotification *)pNotification
{
    NSLog(@"handleReloadFavorites");
    m_bProcessingOver = NO;
    m_arrStations = [[NSMutableArray alloc] init];
    [m_ctrlTblStations reloadData];
    [self performSelector:@selector(prepareStationList) withObject:nil afterDelay:0.0];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleReloadFavorites:)	 name:@"EVENT_RELOAD_FAVORITES"
												object:nil];

    

    [m_ctrlActivity startAnimating];
    m_ctrlActivity.hidden = NO;
    m_bProcessingOver = NO;
    m_arrStations = [[NSMutableArray alloc] init];
    
    [self performSelector:@selector(prepareStationList) withObject:nil afterDelay:0.0];
    
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
