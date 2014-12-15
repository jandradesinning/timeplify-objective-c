//
//  Defines.h
//  Timeplify
//
//  Created by Anil on 04/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <Foundation/Foundation.h>

#define INT_WELCOME_TRAINS_IN_A_ROW     5
#define INT_FAV_TRAINS_IN_A_ROW         6

#define INT_DIRECTION_NORTH     1
#define INT_DIRECTION_SOUTH     2
#define INT_DIRECTION_EITHER    3

#define STR_DIRECTION_NORTH     @"North"
#define STR_DIRECTION_SOUTH     @"South"
#define STR_DIRECTION_EITHER    @"Either"


#define INT_FLOW_COVER_SIZE     0.205047
#define INT_FLOW_COVER_SPREAD   0.328076
#define INT_FLOW_COVER_ZOOM     0.225552

#define INT_STATION_SEL_FROM_WELCOME    1
#define INT_STATION_SEL_FROM_SEE_ALL    2
#define INT_STATION_SEL_FROM_FAV        3


#define STR_KEY_FAV_TRAINS       @"FAV_TRAINS"


#define INT_LEFT_NAV_MOVE_DISTANCE      258


@protocol Defines <NSObject>

@end
