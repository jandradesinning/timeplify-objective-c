//
//  TrainSelectViewController.m
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "TrainSelectViewController.h"
#import "TrainSelectCellView.h"

#import "StationSelectViewController.h"

#import "Defines.h"
#import "GlobalCaller.h"
#import "ST_Train.h"
#import "Utility.h"
#import "DataManager.h"

#import <Parse/Parse.h>

@interface TrainSelectViewController ()

@end

@implementation TrainSelectViewController


-(void) makeBusy
{
    m_ctrlTable.hidden = YES;
    m_ctrlBtnNext.enabled = NO;
    m_ctrlActivity.hidden = NO;
    [m_ctrlActivity startAnimating];
}

-(void) makeReady
{
    m_ctrlTable.hidden = NO;
    m_ctrlBtnNext.enabled = YES;
    m_ctrlActivity.hidden = YES;
}

#pragma mark Table


-(TrainSelectCellView*) getTrainSelectCellView:(UITableView *)tableView
{
    NSString *CellIdentifier = @"TrainSelectCellView";
    
    TrainSelectCellView *cell = (TrainSelectCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TrainSelectCellView" owner:self options:nil];
        
        for (id currentObject in topLevelObjects)
        {
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell =  (TrainSelectCellView *) currentObject;
                break;
            }
        }
        
    }
    
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int iCount = (int)[m_arrRecords count] / INT_WELCOME_TRAINS_IN_A_ROW;
    
    if (([m_arrRecords count] % INT_WELCOME_TRAINS_IN_A_ROW) > 0) {
        iCount++;
    }
    
   return iCount;
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
    
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  
    
    TrainSelectCellView* cell = [self getTrainSelectCellView:tableView];
    cell.m_iRowIndex = (int) indexPath.row;
    cell.m_arrTrains = m_arrRecords;
    [cell setValues];
    
    return cell;
    
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

-(IBAction) btnNextClicked:(id)sender
{
    
    
    NSMutableArray* oArrFav = [GlobalCaller getFavTrainsArray];
    [oArrFav removeAllObjects];
    for (int i= 0; i < [m_arrRecords count]; i++) {
        ST_Train* oTrain = [m_arrRecords objectAtIndex:i];
        if (oTrain.m_bSelected == YES) {
            [oArrFav addObject:oTrain];
        }
    }
    
    if ([oArrFav count] < 1) {
        return;
    }

    
    
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    
    NSArray* oArr = (NSArray*) [Utility getObjectFromDefault:STR_KEY_FAV_TRAINS];
    if (oArr != nil) {
        viewController.m_iScreenMode = INT_STATION_SEL_FROM_FAV;
    }
    else
    {
        viewController.m_iScreenMode = INT_STATION_SEL_FROM_WELCOME;
        viewController.m_iWelomeTrainStep = 0;
    }

    
    
    
    [self.navigationController pushViewController:viewController animated:YES];
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	
	
	if (alertView.tag == INT_ALERT_TAG_RETRY) {
	
		[self getServerAppSettings];
	}
	
    
}



-(void) displayError:(NSString*)IN_strMsg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Timeplify"
													message:IN_strMsg
												   delegate:self cancelButtonTitle:@"Retry" otherButtonTitles: nil];
	alert.tag = INT_ALERT_TAG_RETRY;
	
	[alert show];


}

-(void) readTrainList
{
   
    m_arrRecords = [GlobalCaller getAllTrainsArray];
    
    [m_ctrlTable reloadData];
}


#pragma mark ServerAppSettings

-(void)parseServerAppSettingsResponse:(NSDictionary*)IN_Dict
{
    if (!([IN_Dict isKindOfClass:[NSDictionary class]])) {
        [self displayError:@"Invalid response from server"];
        return;
    }

    
    NSMutableDictionary* oD2 = [[NSMutableDictionary alloc] initWithDictionary:IN_Dict];
    [Utility saveDictInDefault:@"DICT_APP_SETTINGS" :oD2];
 
     
    [Utility saveStringInDefault:@"DATA_COPIED" :@"YES"];
    [self readTrainList];

}


-(void) getServerAppSettings
{
    [self makeBusy];
    
    NSMutableDictionary* oDictParam= [[NSMutableDictionary alloc] init];
    [oDictParam setObject:@"1.0" forKey:@"appVersion"];
    [oDictParam setObject:@"" forKey:@"updatedTime"];
    
    
    
    [PFCloud callFunctionInBackground:@"getSettings" withParameters:oDictParam
                                block:^(id result, NSError *error)
     {
         [self makeReady];
         
         if (error) {
             
             [self displayError:[error localizedDescription]];
             
         }
         else
         {
             [self parseServerAppSettingsResponse: result];
         }
         
         //NSLog(@"Over");
         
     }];
    
    
    //NSLog(@"Called");
    

}

#pragma mark Others


-(void) getLocallyStoredTrains
{
    
    NSMutableDictionary* oDictTempFav = [[NSMutableDictionary alloc] init];
    NSMutableArray* oArrFavTrains = [GlobalCaller getFavTrainsArray];
    for (int j = 0; j <[oArrFavTrains count]; j++)
    {
        ST_Train* oFAvTrain = [oArrFavTrains objectAtIndex:j];
        [oDictTempFav setObject:@"YES" forKey:oFAvTrain.m_strId];
    }
    
    
    m_arrRecords = [GlobalCaller getAllTrainsArray];
    
    
    
    for (int i = 0; i <[m_arrRecords count]; i++) {
        ST_Train* oTrain = [m_arrRecords objectAtIndex:i];
        
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
    
    [m_ctrlTable reloadData];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    m_ctrlActivity.hidden = YES;
   
    m_arrRecords = [[NSMutableArray alloc] init];
    
    
    NSArray* oArr = (NSArray*) [Utility getObjectFromDefault:STR_KEY_FAV_TRAINS];
    if (oArr != nil) {
        
        [self getLocallyStoredTrains];
    }
    else
    {
        [self getServerAppSettings];
        
    }
  
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
