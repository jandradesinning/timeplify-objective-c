//
//  DataManager.h
//  Timeplify
//
//  Created by Anil on 28/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h> 

@interface DataManager : NSObject
{
    
}
+(NSString*) getDBPath;
+(void) checkAndCopyDatabase;
+(void) executeSQL:(NSString*)IN_strSQL;
+(NSMutableArray*) getAllTrains;
+(NSMutableArray*) getAllStations;
+(NSMutableArray*) getStationsOfTrain:(NSString*)IN_strTrain;
+(NSMutableArray*) getStationsOfTrainStopInStation:(NSString*)IN_strStationId;
+(void)insertServerData:(NSDictionary*)IN_Dict;
@end
