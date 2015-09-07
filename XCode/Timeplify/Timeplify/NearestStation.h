//
//  NearestStation.h
//  Timeplify
//
//  Created by Anil on 26/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ST_Station;

@interface NearestStation : NSObject
{
    
}
-(NSMutableArray*) getNearestStations;
-(NSMutableArray*) getStationsWithRoutesOfFirstNearestStation;

-(ST_Station*) getPrevStationofStation:(ST_Station*) IN_Station :(int)IN_iDirection;
-(ST_Station*) getNextStationofStation:(ST_Station*) IN_Station :(int)IN_iDirection;
@end
