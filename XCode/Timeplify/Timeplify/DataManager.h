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
+(NSString*) getSQLStringField:(sqlite3_stmt*)IN_stmt :(int) IN_iIndex;
+(NSString*) getDBPath;
+(void) checkAndCopyDatabase;
+(void) executeSQL:(NSString*)IN_strSQL :(sqlite3 *)IN_Database;
+(NSMutableArray*) getLocalScheduledData:(NSString*)IN_strStationId : (NSString*) IN_strDirection;
+(NSMutableArray*) getAllTrains;
+(NSMutableArray*) getAllStations;
+(NSMutableArray*) getStationsOfTrain:(NSString*)IN_strTrain;
+(NSMutableArray*) getStationsOfTrainStopInStation:(NSString*)IN_strStationId;
+(void)insertServerData:(NSDictionary*)IN_Dict;
@end
