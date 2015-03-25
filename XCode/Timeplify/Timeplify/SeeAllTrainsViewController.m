//
//  SeeAllTrainsViewController.m
//  Timeplify
//
//  Created by Anil on 25/03/15.
//  Copyright (c) 2015 Anil. All rights reserved.
//

#import "SeeAllTrainsViewController.h"

#import "SeeAllTrainsCellView.h"
#import "StationSelectViewController.h"

#import "Defines.h"
#import "GlobalCaller.h"
#import "ST_Train.h"
#import "Utility.h"
#import "DataManager.h"

@interface SeeAllTrainsViewController ()

@end

@implementation SeeAllTrainsViewController


#pragma mark Table


-(SeeAllTrainsCellView*) getSeeAllTrainsCellView:(UITableView *)tableView
{
    NSString *CellIdentifier = @"SeeAllTrainsCellView";
    
    SeeAllTrainsCellView *cell = (SeeAllTrainsCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SeeAllTrainsCellView" owner:self options:nil];
        
        for (id currentObject in topLevelObjects)
        {
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell =  (SeeAllTrainsCellView *) currentObject;
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
    
    
    SeeAllTrainsCellView* cell = [self getSeeAllTrainsCellView:tableView];
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


-(void) readTrainList
{
    
    m_arrRecords = [GlobalCaller getAllTrainsArray];
    
    [m_ctrlTable reloadData];
}




-(void)handleSeeAllTrainSelected:(NSNotification *)pNotification
{
    NSNumber* oNum = [pNotification object];
    int iPos = [oNum intValue];
    
    StationSelectViewController* viewController = [[StationSelectViewController alloc] initWithNibName:@"StationSelectViewController" bundle:nil];
    
    viewController.m_iScreenMode = INT_STATION_SEL_FROM_SEE_ALL;
    viewController.m_iTrainIndex = iPos;
    
    [self.navigationController pushViewController:viewController animated:YES];

}

-(IBAction) btnBackClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleSeeAllTrainSelected:)	 name:@"EVENT_SEE_ALL_TRAIN_SELECTED"
												object:nil];

    
    [self readTrainList];
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
