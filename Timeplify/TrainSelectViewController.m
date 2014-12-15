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

@interface TrainSelectViewController ()

@end

@implementation TrainSelectViewController


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
    int iCount = [m_arrRecords count] / INT_WELCOME_TRAINS_IN_A_ROW;
    
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
    cell.m_iRowIndex =indexPath.row;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"Data.plist" ofType:nil];
    NSDictionary* oDict = [NSDictionary dictionaryWithContentsOfFile:filepath];
    NSArray* oArr = [oDict objectForKey:@"Trains"];
    m_arrRecords = [[NSMutableArray alloc] init];
    
    for (int i = 0; i <[oArr count]; i++) {
        NSDictionary* oDict2 = [oArr objectAtIndex:i];
        
        ST_Train* oTrain = [[ST_Train alloc] init];
        oTrain.m_iIndex = i;
        oTrain.m_strName = [oDict2 objectForKey:@"Name"];
        oTrain.m_strImage = [oDict2 objectForKey:@"Image"];
        oTrain.m_bSelected = NO;
        [m_arrRecords addObject:oTrain];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
