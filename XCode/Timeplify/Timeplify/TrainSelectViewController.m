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
    
    
    
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    viewController.m_iScreenMode = INT_STATION_SEL_FROM_WELCOME;
    
    
    [self.navigationController pushViewController:viewController animated:YES];
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	
	
	if (alertView.tag == INT_ALERT_TAG_RETRY) {
	
		[self getServerStaticData];
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


-(void)parseServerResponse:(NSDictionary*)IN_Dict
{
    if (!([IN_Dict isKindOfClass:[NSDictionary class]])) {
        [self displayError:@"Invalid response from server"];
        return;
    }
    
    [Utility saveObjectInDefault:@"SERVER_STATIC_DATA" :IN_Dict];
    
     NSArray* arrStations = [IN_Dict objectForKey:@"stations"];
    
    for (int i = 0; i <[arrStations count]; i++) {
        NSDictionary* oDict = [arrStations objectAtIndex:i];
        NSString* strId = [oDict objectForKey:@"id"];
        NSString* strKey = [NSString stringWithFormat:@"STATION_INFO_%@", strId];
        [Utility saveObjectInDefault:strKey :oDict];
    }

    
    [self readTrainList];
  
}
-(void) getServerStaticData
{
    NSDictionary* oDict = (NSDictionary*)[Utility getObjectFromDefault:@"SERVER_STATIC_DATA"];
    if (oDict != nil) {
        [self readTrainList];
        return;
    }
    
    
    [self makeBusy];
    
    NSMutableDictionary* oDictParam= [[NSMutableDictionary alloc] init];
    [oDictParam setObject:@"1.0" forKey:@"appVersion"];
    [oDictParam setObject:@"" forKey:@"updatedTime"];
    
    [PFCloud callFunctionInBackground:@"getStaticData" withParameters:oDictParam
                                block:^(id result, NSError *error)
     {
         [self makeReady];
         
         if (error) {
             
             [self displayError:[error localizedDescription]];
             
             }
         else
         {
             [self parseServerResponse: result];
         }
         
         NSLog(@"Over");
         
     }];
   
    
    NSLog(@"Called");
    
    
    
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    m_ctrlActivity.hidden = YES;
   
    m_arrRecords = [[NSMutableArray alloc] init];
  
    
    [self getServerStaticData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
