//
//  StationSelectViewController.m
//  Timeplify
//
//  Created by Anil on 07/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "StationSelectViewController.h"

#import "StationSelectCellView.h"

#import "AllSetViewController.h"

#import "Defines.h"
#import "ST_Train.h"
#import "ST_Station.h"
#import "GlobalCaller.h"
#import "DirectionView.h"

#import "DataManager.h"

#import "Utility.h"

@interface StationSelectViewController ()

@end

@implementation StationSelectViewController

@synthesize m_iScreenMode;

-(void) getStations
{
    [m_arrAllValues removeAllObjects];
    [m_arrAllValues removeAllObjects];
    
    if (m_iTrainIndex < 0) {
        
        [m_ctrlTable reloadData];
        [m_searchDisplayController.searchResultsTableView reloadData];
        return;
    }
    
    NSMutableDictionary* oDictTempFav = [[NSMutableDictionary alloc] init];
    NSMutableArray* oArrFavStations = [GlobalCaller getFavStationsArray];
    for (int j = 0; j <[oArrFavStations count]; j++)
    {
        ST_Station* oFAvStation = [oArrFavStations objectAtIndex:j];
        NSNumber* oDirection = [NSNumber numberWithInt:oFAvStation.m_iSelectedDirection];
        [oDictTempFav setObject:oDirection forKey:oFAvStation.m_strStationId];
    }
   
    
    
    ST_Train* oTrain = [m_arrTrains objectAtIndex:m_iTrainIndex];
    
    NSMutableArray* oArrStations = [DataManager getStationsOfTrain:oTrain.m_strId];
    
    
    for (int i = 0; i <[oArrStations count]; i++) {
        ST_Station* oStation =  [oArrStations objectAtIndex:i];
      
        oStation.m_iSelectedDirection = 0;
        
        
        NSNumber* oDirection = [oDictTempFav objectForKey:oStation.m_strStationId];
        if (oDirection != nil) {
            oStation.m_iSelectedDirection = [oDirection intValue];
        }
        [m_arrAllValues addObject:oStation];

    }
    
    [m_ctrlTable reloadData];
    [m_searchDisplayController.searchResultsTableView reloadData];
    
}

#pragma mark FlowCover


- (int)flowCoverNumberImages:(FlowCoverView *)view
{
    return (int)[m_arrTrains count];
}

- (UIImage *)flowCover:(FlowCoverView *)view cover:(int)image
{
    ST_Train* oTrain = [m_arrTrains objectAtIndex:image];
    NSString* strNormalImage = [NSString stringWithFormat:@"vehicle-logo-%@.png", oTrain.m_strImage];
    strNormalImage = [strNormalImage lowercaseString];
    UIImage* oImage = [UIImage imageNamed:strNormalImage];
    return oImage;
    
    
}

-(void) doDelayedgetStations
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self getStations];
    m_ctrlTable.hidden = NO;
    m_ctrlActivity.hidden = YES;
}

- (void)flowCover:(FlowCoverView *)view didSelect:(int)image
{
   
    
}


- (void)flowCover:(FlowCoverView *)view didComeToStop:(int)image
{
    if (image != m_iTrainIndex) {
        
        NSLog(@"Selected Index %d",image);
        m_iTrainIndex = image;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        m_ctrlTable.hidden = YES;
        m_ctrlActivity.hidden = NO;
        [self performSelector:@selector(doDelayedgetStations) withObject:nil afterDelay:0.0];
        
    }
    
}




#pragma mark DirectionView


- (void)animationToShowDirectionViewStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {
    
}

- (void)animationToHideDirectionViewStopped:(NSString *)animationID finished:(NSNumber *) finished context:(void *) context {

    m_DirectionView.hidden = YES;
}


-(void) showDirectionView:(ST_Station*)IN_Station
{
    m_DirectionView.m_Station = IN_Station;
    [m_DirectionView setValues];
    
    m_DirectionView.hidden = NO;
    m_DirectionView.alpha = 0.0;
    m_DirectionView.center = self.view.center;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToShowDirectionViewStopped:finished:context:)];
    
    m_DirectionView.alpha = 1.0;
    
    [UIView commitAnimations];
    
}

-(void) hideDirectionView
{
    
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationToHideDirectionViewStopped:finished:context:)];
    
    m_DirectionView.alpha = 0.0;
    
    [UIView commitAnimations];
    
}

-(DirectionView*) getDirectionView
{
    DirectionView* oView = nil;
    
    NSArray *topLevelObjects;
    
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"DirectionView" owner:self options:nil];
    
	for (id currentObject in topLevelObjects){
		if ([currentObject isKindOfClass:[DirectionView class]]){
			oView =  (DirectionView *) currentObject;
			break;
		}
	}
    return oView;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (m_DirectionView.hidden == NO) {
        [self hideDirectionView];
    }
}

#pragma mark Table


-(StationSelectCellView*) getStationSelectCellView:(UITableView *)tableView
{
    NSString *CellIdentifier = @"StationSelectCellView";
    
    StationSelectCellView *cell = (StationSelectCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"StationSelectCellView" owner:self options:nil];
        
        for (id currentObject in topLevelObjects)
        {
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell =  (StationSelectCellView *) currentObject;
                break;
            }
        }
        
    }
    
    return cell;
}



- (void) rowSelected:(NSIndexPath *)indexPath :(UITableView *)IN_tableView
{
	[m_ctrlTable deselectRowAtIndexPath:indexPath animated:YES];
    
    ST_Station* oStation;
    
    if (IN_tableView == m_ctrlTable) {
        
        oStation = [m_arrAllValues objectAtIndex:indexPath.row];
    }
    else
    {
        oStation = [m_arrSearchValues objectAtIndex:indexPath.row];
    }
    
    if (m_iScreenMode == INT_STATION_SEL_FROM_SEE_ALL) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_ONE_ALL_STATION_SELECTED" object:oStation];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    
    

    
    if (oStation.m_iSelectedDirection > 0) {
        oStation.m_iSelectedDirection = 0;
        [self updateVisibleCells:m_ctrlTable];
        [self updateVisibleCells:m_searchDisplayController.searchResultsTableView];
        
        [GlobalCaller updateFavStation:oStation];
        return;
    }
    
    
    
    [m_searchDisplayController setActive:NO animated:YES];
    [self showDirectionView:oStation];
    NSLog(@"Selected '%@'", oStation.m_strStationName);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    m_searchDisplayController.searchResultsTableView.delegate = self;
    
    int rows = 0;
    
    if (tableView == m_ctrlTable) {
        rows = (int)[m_arrAllValues count];
    }
    if(tableView == self.searchDisplayController.searchResultsTableView){
        rows = (int)[m_arrSearchValues count];
    }
    
    return rows;
    
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	[self rowSelected:indexPath: tableView];
	
}

- (void)tableView:(UITableView *)tableview didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	
	[self rowSelected:indexPath: tableview];
	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    StationSelectCellView *cell = [self getStationSelectCellView:tableView];
    
    
    ST_Station* oStation;
    
    if (tableView == m_ctrlTable) {
        
        oStation = [m_arrAllValues objectAtIndex:indexPath.row];
    }
    else
    {
        oStation = [m_arrSearchValues objectAtIndex:indexPath.row];
    }
    
       
    
    cell.m_Station = oStation;
    cell.m_iRowIndex = (int)indexPath.row;
    cell.m_iScreenMode = m_iScreenMode;
    [cell setValues];
    return cell;
        
}

- (CGFloat)tableView:(UITableView *)tableview heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [m_arrSearchValues removeAllObjects];
    
    
    for(int i = 0; i < [m_arrAllValues count]; i++)
    {
        ST_Station* oStation = [m_arrAllValues objectAtIndex:i];
        
        NSString* strTxt = oStation.m_strStationName;
        NSString* strUp1 = [searchString uppercaseString];
        NSString* strUp2 = [strTxt uppercaseString];
        
        if ([strUp2 rangeOfString:strUp1].location != NSNotFound) {
            [m_arrSearchValues addObject:oStation];
        }
        
    }
    
    return YES;
}



-(void) updateVisibleCells:(UITableView*)IN_TableView
{
    for (int i = 0; i < [IN_TableView.visibleCells count]; i++) {
        StationSelectCellView* oCell = [IN_TableView.visibleCells objectAtIndex:i];
        [oCell setValues];
    }
}


#pragma mark - Others

-(IBAction) btnDoneClicked:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
-(IBAction) btnNextClicked:(id)sender
{
    if (m_iScreenMode == INT_STATION_SEL_FROM_WELCOME) {
        AllSetViewController* viewController = [[AllSetViewController alloc] initWithNibName:@"AllSetViewController" bundle:nil];
       
        [self.navigationController pushViewController:viewController animated:YES];
    }
    
}

-(IBAction) btnBackClicked:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) arrangeTable
{
    CGRect oRct = m_ctrlTable.frame;
    oRct.size.height = self.view.frame.size.height - oRct.origin.y;
    m_ctrlTable.frame = oRct;
    
}


-(void) applyMode
{
    if (m_iScreenMode == INT_STATION_SEL_FROM_FAV) {
        m_ctrlBtnNext.hidden = YES;
        m_ctrlBtnDone.hidden = NO;
        m_ctrlBtnBack.hidden = YES;
        m_ctrlLblTitle.text = @"Select your station(s)";
        [self arrangeTable];
    }
    
    if (m_iScreenMode == INT_STATION_SEL_FROM_SEE_ALL)
    {
        m_ctrlBtnNext.hidden = YES;
        m_ctrlBtnDone.hidden = YES;
        m_ctrlBtnBack.hidden = NO;
        [self arrangeTable];
        m_ctrlLblTitle.text = @"All stations";
    }
    
    if (m_iScreenMode == INT_STATION_SEL_FROM_WELCOME)
    {
        m_ctrlBtnNext.hidden = NO;
        m_ctrlBtnDone.hidden = YES;
        m_ctrlBtnBack.hidden = YES;
    }
}

-(void) viewWillAppear:(BOOL)animated
{
    m_DirectionView.frame = self.view.frame;
    
    [self applyMode];
}



-(void)handleHideDirectionView:(NSNotification *)pNotification
{
    [self updateVisibleCells:m_ctrlTable];
    [self updateVisibleCells:m_searchDisplayController.searchResultsTableView];
    [self hideDirectionView];
    
}

-(void) getTrains
{
    NSMutableArray* oArrFavTrains = [GlobalCaller getFavTrainsArray];
    for (int i = 0; i <[oArrFavTrains count]; i++) {
        ST_Train* oTrain = [oArrFavTrains objectAtIndex:i];
        oTrain.m_iIndex = i;
        [m_arrTrains addObject:oTrain];
    }

    if ([m_arrTrains count] > 0) {
        m_iTrainIndex = 0;
        [m_ctrlFlowCover setCurrentIndex:0];
        [self getStations];
    }
  
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    m_iTrainIndex = -1;
    
    m_ctrlActivity.hidden = YES;
    [m_ctrlActivity startAnimating];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter]	 addObserver:self	 selector:@selector(handleHideDirectionView:)	 name:@"EVENT_HIDE_DIRECTION_VIEW"
												object:nil];

    
    
    m_arrAllValues = [[NSMutableArray alloc] init];
    m_arrSearchValues = [[NSMutableArray alloc] init];
    m_arrTrains = [[NSMutableArray alloc] init];
    
    [self getTrains];
    
    
    
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor lightGrayColor]];
    
    
    m_ctrlSearchBar.placeholder = @"";
    m_ctrlSearchBar.showsCancelButton = YES;
    
    m_searchDisplayController = [[UISearchDisplayController alloc]
                                 initWithSearchBar:m_ctrlSearchBar
                                 contentsController:self ];
    
    
    m_searchDisplayController.delegate = self;
    m_searchDisplayController.searchResultsDataSource = self;
    m_searchDisplayController.searchResultsDelegate = self;
    m_searchDisplayController.searchResultsTableView.delegate = self;
    
    
    
    
    m_searchDisplayController.searchResultsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    m_ctrlTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [m_searchDisplayController setActive:NO animated:NO];
    
    
    
    m_DirectionView = [self getDirectionView];
    [m_DirectionView initCtrl];
    m_DirectionView.hidden = YES;
    m_DirectionView.alpha = 0.0;
    [self.view addSubview:m_DirectionView];

    
    m_ctrlFlowCover.m_IMAGE_SIZE = INT_FLOW_COVER_SIZE;
    m_ctrlFlowCover.m_IMAGE_SPREAD = INT_FLOW_COVER_SPREAD;
    m_ctrlFlowCover.m_IMAGE_ZOOM = INT_FLOW_COVER_ZOOM;
    
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
