//
//  GlobalCaller.h
//  Timeplify
//
//  Created by Anil on 08/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ST_Station;
@class ST_Train;

@interface GlobalCaller : NSObject
{
    
}
+(NSMutableArray*) getFavTrainsArray;
+(NSMutableArray*) getFavStationsArray;
+(NSMutableArray*) getAllTrainsArray;
+(void) updateFavTrain:(ST_Train*)IN_Train;
+(void) updateFavStation:(ST_Station*)IN_Station;
@end
