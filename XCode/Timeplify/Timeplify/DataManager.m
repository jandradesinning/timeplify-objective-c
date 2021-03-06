//
//  DataManager.m
//  Timeplify
//
//  Created by Anil on 28/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "DataManager.h"
#import "Utility.h"
#import "Defines.h"
#import "ST_Train.h"
#import "ST_Station.h"

@implementation DataManager


+(NSString*) getSQLStringField:(sqlite3_stmt*)IN_stmt :(int) IN_iIndex
{
	
	NSString *strTemp;
	
	char* pTemp = (char*)sqlite3_column_text(IN_stmt, IN_iIndex);
	if (pTemp != NULL)
		strTemp = [NSString stringWithUTF8String:pTemp];
	else
		strTemp = @"";
	
	if (strTemp == nil)
	{
		strTemp = @"";
	}
	
	return strTemp;
	
}


+(NSMutableArray*) getLocalScheduledData:(NSString*)IN_strStationId : (NSString*) IN_strDirection
{
    NSString* strSql =  [NSString stringWithFormat:@"SELECT ServiceID, RouteId, ArrivalTime FROM ScheduledData WHERE StationID = '%@' AND Direction = '%@' order by ArrivalTime", IN_strStationId, IN_strDirection];
    
    
    NSMutableArray *arrReturn= [[NSMutableArray alloc]init];
    
    NSString* strFile = [DataManager getDBPath];
    
    sqlite3 *objSQLite3;
	
	int result= sqlite3_open([strFile UTF8String],&objSQLite3);
	if(result!=SQLITE_OK){
		return arrReturn;
	}
    
    sqlite3_stmt *compiledStatement;
	result=sqlite3_prepare_v2(objSQLite3, [strSql UTF8String],-1,  &compiledStatement, NULL);
    
    int iIndex = 0;
    while(sqlite3_step(compiledStatement) == SQLITE_ROW)
	{
		NSMutableDictionary* oDict = [[NSMutableDictionary alloc] init];
        
        
        
        
        NSString *strTemp = [DataManager getSQLStringField:compiledStatement: 0];
        [oDict setObject:strTemp forKey:@"ServiceId"];
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 1];
        [oDict setObject:strTemp forKey:@"routeId"];
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 2];
        [oDict setObject:strTemp forKey:@"arrivalTime"];
         
		[arrReturn addObject:oDict];
        iIndex++;
	}
	
	sqlite3_finalize(compiledStatement);
	sqlite3_close(objSQLite3);
	
    return arrReturn;
    
}





+(NSMutableArray*) getStationsOfTrain:(NSString*)IN_strTrain
{
    NSString* strSql = [NSString stringWithFormat: @"SELECT TrainStop.StationId,  TrainStop.RouteId, TrainStop.DirOrder, Station.Name, Train.Name, TrainStop.North, TrainStop.South, Station.Latitude, Station.Longitude FROM Train, TrainStop, Station where Train.Id = TrainStop.RouteId AND Station.Id = TrainStop.StationId AND Train.Id = '%@' ORDER BY TrainStop.DirOrder", IN_strTrain ];
    
    
    NSMutableArray *arrReturn= [[NSMutableArray alloc]init];
    
    NSString* strFile = [DataManager getDBPath];
    
    sqlite3 *objSQLite3;
	
	int result= sqlite3_open([strFile UTF8String],&objSQLite3);
	if(result!=SQLITE_OK){
		return arrReturn;
	}
    
    sqlite3_stmt *compiledStatement;
	result=sqlite3_prepare_v2(objSQLite3, [strSql UTF8String],-1,  &compiledStatement, NULL);
    
    int iIndex = 0;
    while(sqlite3_step(compiledStatement) == SQLITE_ROW)
	{
		ST_Station *oStation = [[ST_Station alloc] init];
        oStation.m_iIndex = iIndex;
        
        NSString *strTemp = [DataManager getSQLStringField:compiledStatement: 0];
        oStation.m_strStationId = strTemp;
		
        strTemp = [DataManager getSQLStringField:compiledStatement: 1];
        oStation.m_strRouteId = strTemp;
        
        oStation.m_iOrder = sqlite3_column_int(compiledStatement, 2);
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 3];
        oStation.m_strStationName = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 4];
        oStation.m_strTrainName = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 5];
        oStation.m_strNorthDirection = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 6];
        oStation.m_strSouthDirection = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 7];
        oStation.m_dbLatitude = [strTemp doubleValue];
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 8];
        oStation.m_dbLongitude = [strTemp doubleValue];
        
		[arrReturn addObject:oStation];
        iIndex++;
	}
	
	sqlite3_finalize(compiledStatement);
	sqlite3_close(objSQLite3);
	
    return arrReturn;
    
}


+(NSMutableArray*) getStationsOfTrainStopInStation:(NSString*)IN_strStationId
{
    NSString* strSql = [NSString stringWithFormat: @"SELECT TrainStop.StationId,  TrainStop.RouteId, TrainStop.DirOrder, Station.Name, Train.Name, TrainStop.North, TrainStop.South, Station.Latitude, Station.Longitude FROM Train, TrainStop, Station where Train.Id = TrainStop.RouteId AND Station.Id = TrainStop.StationId AND Station.Id = '%@' ORDER BY TrainStop.DirOrder", IN_strStationId ];
    
    
    NSMutableArray *arrReturn= [[NSMutableArray alloc]init];
    
    NSString* strFile = [DataManager getDBPath];
    
    sqlite3 *objSQLite3;
	
	int result= sqlite3_open([strFile UTF8String],&objSQLite3);
	if(result!=SQLITE_OK){
		return arrReturn;
	}
    
    sqlite3_stmt *compiledStatement;
	result=sqlite3_prepare_v2(objSQLite3, [strSql UTF8String],-1,  &compiledStatement, NULL);
    
    int iIndex = 0;
    while(sqlite3_step(compiledStatement) == SQLITE_ROW)
	{
		ST_Station *oStation = [[ST_Station alloc] init];
        oStation.m_iIndex = iIndex;
        
        NSString *strTemp = [DataManager getSQLStringField:compiledStatement: 0];
        oStation.m_strStationId = strTemp;
		
        strTemp = [DataManager getSQLStringField:compiledStatement: 1];
        oStation.m_strRouteId = strTemp;
        
        oStation.m_iOrder = sqlite3_column_int(compiledStatement, 2);
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 3];
        oStation.m_strStationName = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 4];
        oStation.m_strTrainName = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 5];
        oStation.m_strNorthDirection = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 6];
        oStation.m_strSouthDirection = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 7];
        oStation.m_dbLatitude = [strTemp doubleValue];
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 8];
        oStation.m_dbLongitude = [strTemp doubleValue];
        
		[arrReturn addObject:oStation];
        iIndex++;
	}
	
	sqlite3_finalize(compiledStatement);
	sqlite3_close(objSQLite3);
	
    return arrReturn;
    
}


+(NSMutableArray*) getAllStations
{
    NSString* strSql =  @"SELECT DISTINCT Station.* FROM TrainStop, Station WHERE Station.Id = TrainStop.StationId order by Station.Id";
    
    NSMutableArray *arrReturn= [[NSMutableArray alloc]init];
    
    NSString* strFile = [DataManager getDBPath];
    
    sqlite3 *objSQLite3;
	
	int result= sqlite3_open([strFile UTF8String],&objSQLite3);
	if(result!=SQLITE_OK){
		return arrReturn;
	}
    
    sqlite3_stmt *compiledStatement;
	result=sqlite3_prepare_v2(objSQLite3, [strSql UTF8String],-1,  &compiledStatement, NULL);
    
    int iIndex = 0;
    while(sqlite3_step(compiledStatement) == SQLITE_ROW)
	{
		ST_Station *oStation = [[ST_Station alloc] init];
        oStation.m_iIndex = iIndex;
        
        NSString *strTemp = [DataManager getSQLStringField:compiledStatement: 0];
        oStation.m_strStationId = strTemp;
		
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 1];
        oStation.m_strStationName = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 2];
        oStation.m_dbLatitude = [strTemp doubleValue];
    
        strTemp = [DataManager getSQLStringField:compiledStatement: 3];
        oStation.m_dbLongitude = [strTemp doubleValue];
        
        oStation.m_iOrder = sqlite3_column_int(compiledStatement, 4);
        
        
		[arrReturn addObject:oStation];
        iIndex++;
	}
	
	sqlite3_finalize(compiledStatement);
	sqlite3_close(objSQLite3);
	
    return arrReturn;
    
}


+(NSMutableArray*) getAllTrains
{
    NSString* strSql =  @"SELECT Train.*, S1.Name AS NorthName, S2.Name AS SouthName FROM Train, Station S1, Station S2 WHERE Train.NorthStationId = S1.Id AND Train.SouthStationId = S2.Id order by Id";
    
    NSMutableArray *arrReturn= [[NSMutableArray alloc]init];
    
    NSString* strFile = [DataManager getDBPath];
    
    sqlite3 *objSQLite3;
	
	int result= sqlite3_open([strFile UTF8String],&objSQLite3);
	if(result!=SQLITE_OK){
		return arrReturn;
	}
  
    sqlite3_stmt *compiledStatement;
	result=sqlite3_prepare_v2(objSQLite3, [strSql UTF8String],-1,  &compiledStatement, NULL);
    
    int iIndex = 0;
    while(sqlite3_step(compiledStatement) == SQLITE_ROW)
	{
		ST_Train *oTrain = [[ST_Train alloc] init];
        oTrain.m_iIndex = iIndex;
        
        NSString *strTemp = [DataManager getSQLStringField:compiledStatement: 0];
        oTrain.m_strId = strTemp;
		
        strTemp = [DataManager getSQLStringField:compiledStatement: 1];
        oTrain.m_strName = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 2];
        oTrain.m_strImage = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 3];
        oTrain.m_strNorthStationId = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 4];
        oTrain.m_strSouthStationId = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 5];
        oTrain.m_strNorthStationName = strTemp;
        
        strTemp = [DataManager getSQLStringField:compiledStatement: 6];
        oTrain.m_strSouthStationName = strTemp;
        
		      
		[arrReturn addObject:oTrain];
        iIndex++;
	}
	
	sqlite3_finalize(compiledStatement);
	sqlite3_close(objSQLite3);
	
    
    return arrReturn;
    
}




+(void) executeSQL:(NSString*)IN_strSQL :(sqlite3 *)IN_Database
{
    sqlite3_exec(IN_Database, [IN_strSQL UTF8String],	 NULL, NULL, NULL);
}


+(NSString*) getDBPath
{
    NSString* strName = @"Data.sqlite3";
    
    NSString* strFolder = [Utility createAndGetAFolder:STR_FOLDER_DATA_FILES];
    
    NSString* strFile = [strFolder stringByAppendingPathComponent:strName];
    return strFile;
}

+(void) checkAndCopyDatabase
{
 
    NSString* strName = @"Data.sqlite3";
    
    NSString* strFile = [DataManager getDBPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:strFile]) {
        //NSLog(@"File exists");
        return;
    }
    
    // NSLog(@"Copies file '%@'", strFile);
    
    NSString *databasePathFromApp=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:strName];
    
    [[NSFileManager defaultManager] copyItemAtPath:databasePathFromApp toPath:strFile error:nil];
}
@end
