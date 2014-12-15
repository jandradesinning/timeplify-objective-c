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

#import "StationSelectViewController.h"

@interface FavoritesViewController ()

@end

@implementation FavoritesViewController


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
        int iCount = [m_arrTrains count] / INT_FAV_TRAINS_IN_A_ROW;
        
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
        cell.m_iRowIndex =indexPath.row;
        cell.m_arrTrains = m_arrTrains;
        [cell setValues];
        
        return cell;
    }
    
    if (tableView.tag == 1) {
        
        FavStationCellView* cell = [self getFavStationCellView:tableView];
        
        ST_Station* oStation = [m_arrStations objectAtIndex:indexPath.row];
        cell.m_iRowIndex =indexPath.row;
        cell.m_Station = oStation;
        [cell setValues];
        
        return cell;
    }
    
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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
    [m_arrTrains removeAllObjects];
    
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
        [m_arrTrains addObject:oTrain];
    }

}



-(void) getStations
{
    [m_arrStations removeAllObjects];
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"Data.plist" ofType:nil];
    NSDictionary* oDict = [NSDictionary dictionaryWithContentsOfFile:filepath];
    NSArray* oArr = [oDict objectForKey:@"Trains"];
    
    for (int i = 0; i <[oArr count]; i++) {
        NSDictionary* oDict2 = [oArr objectAtIndex:i];
        
        ST_Station* oStation = [[ST_Station alloc] init];
        oStation.m_iIndex = i;
        oStation.m_strName = [oDict2 objectForKey:@"Name"];
        oStation.m_bSelected = NO;
        oStation.m_iSelectedDirection = -1;
        [m_arrStations addObject:oStation];
        
    }
    
}

-(IBAction) btnBackClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction) btnAddClicked:(id)sender
{
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    viewController.m_iScreenMode = INT_STATION_SEL_FROM_FAV;
    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:viewController ];
    navigationController.navigationBarHidden = YES;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
  
    m_arrTrains = [[NSMutableArray alloc] init];
    m_arrStations = [[NSMutableArray alloc] init];
    
    [self getTrains];
    [self getStations];
   
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
