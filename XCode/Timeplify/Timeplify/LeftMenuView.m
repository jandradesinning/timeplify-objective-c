//
//  LeftMenuView.m
//  Timeplify
//
//  Created by anil on 06/09/14.
//  Copyright (c) 2014 anil. All rights reserved.
//

#import "LeftMenuView.h"
#import "LeftMenuCellView.h"

#import "GlobalCaller.h"

@implementation LeftMenuView

@synthesize m_arrNextTrains;

#pragma mark Table


-(LeftMenuCellView*) getLeftMenuCellView:(UITableView *)tableView
{
    NSString *CellIdentifier = @"LeftMenuCellView";
    
    LeftMenuCellView *cell = (LeftMenuCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"LeftMenuCellView" owner:self options:nil];
        
        for (id currentObject in topLevelObjects)
        {
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell =  (LeftMenuCellView *) currentObject;
                break;
            }
        }
        
    }
    
    return cell;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (tableView.tag == 0) {
        
        return ([m_arrNextTrains count]);
    }
    
    return 4;
    
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
    
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    LeftMenuCellView* cell = [self getLeftMenuCellView:tableView];
    
    cell.m_iIndex = (int)(indexPath.row);
    
    if (tableView.tag == 0) {
    
        NSMutableDictionary* oDict = [m_arrNextTrains objectAtIndex:indexPath.row];
        cell.m_dict = oDict;

    }
    else
    {
        cell.m_dict = nil;

    }
    
    [cell setValues];
    
    
    
    return cell;
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_LEFT_MENU_SELECTED" object:indexPath];
    }
    
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}



#pragma mark Others

-(void) setValues:(int) IN_iDirection
{
    m_iDirection = IN_iDirection;
    [m_ctrlTable reloadData];
}

-(void) initControl
{
    m_ctrlTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EVENT_HIDE_LEFT_MENU_VIEW" object:nil];
}



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
