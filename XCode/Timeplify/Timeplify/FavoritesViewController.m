//
//  FavoritesViewController.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "FavoritesViewController.h"
#import "FavTrainCellView.h"
#import "FavStationCellView.h"

#import "Defines.h"
#import "ST_Train.h"
#import "ST_Station.h"
#import "GlobalCaller.h"
#import "StationSelectViewController.h"
#import "Utility.h"

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


-(FavTrainCellView*) getFavTrainCellView:(UITableView *)tableView
{
    NSString *CellIdentifier = @"FavTrainCellView";
    
    FavTrainCellView *cell = (FavTrainCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"FavTrainCellView" owner:self options:nil];
        
        for (id currentObject in topLevelObjects)
        {
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell =  (FavTrainCellView *) currentObject;
                break;
            }
        }
        
    }
    
    return cell;
}



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
    if (tableView.tag == 0) {
        int iCount = (int)[m_arrTrains count] / INT_FAV_TRAINS_IN_A_ROW;
        
        if (([m_arrTrains count] % INT_FAV_TRAINS_IN_A_ROW) > 0) {
            iCount++;
        }
        return iCount;
    }
    
    if (tableView.tag == 1) {
       
        return [m_arrStations count];
    }
    
    return 0;
    
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
    
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 0) {
   
        FavTrainCellView* cell = [self getFavTrainCellView:tableView];
        cell.m_iRowIndex = (int) indexPath.row;
        cell.m_arrTrains = m_arrTrains;
        [cell setValues];
        
        return cell;
    }
    
    if (tableView.tag == 1) {
        
        FavStationCellView* cell = [self getFavStationCellView:tableView];
        
        ST_Station* oStation = [m_arrStations objectAtIndex:(int)indexPath.row];
        cell.m_iRowIndex = (int) indexPath.row;
        cell.m_Station = oStation;
        [cell setValues];
        
        return cell;
    }
    
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    
    if (tableView.tag == 0)
    {
        return NO;
        
    }
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView.tag == 0)
    {
        return;
        
    }
    
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

-(void) getTrains
{
    
    NSMutableDictionary* oDictTempFav = [[NSMutableDictionary alloc] init];
    NSMutableArray* oArrFavTrains = [GlobalCaller getFavTrainsArray];
    for (int j = 0; j <[oArrFavTrains count]; j++)
    {
        ST_Train* oFAvTrain = [oArrFavTrains objectAtIndex:j];
        [oDictTempFav setObject:@"YES" forKey:oFAvTrain.m_strId];
     }
    
    
    m_arrTrains = [GlobalCaller getAllTrainsArray];
   
    
    
    for (int i = 0; i <[m_arrTrains count]; i++) {
        ST_Train* oTrain = [m_arrTrains objectAtIndex:i];
        
        NSString* strFav = [oDictTempFav objectForKey:oTrain.m_strId];
        if (strFav != nil) {
            oTrain.m_bSelected = YES;
        }
        else
        {
            oTrain.m_bSelected = NO;
        }
        
        oTrain.m_iIndex = i;
    }

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
    
    NSMutableArray* oArrFavTrains = [GlobalCaller getFavTrainsArray];
    if ([oArrFavTrains count] < 1) {
        return;
    }

    
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    viewController.m_iScreenMode = INT_STATION_SEL_FROM_FAV;
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];

}

-(void) viewWillAppear:(BOOL)animated
{
    [self getStations];
    [m_ctrlTblStations reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
  
    m_arrTrains = [[NSMutableArray alloc] init];
    m_arrStations = [[NSMutableArray alloc] init];
    
    [self getTrains];
    
   
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
