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


#define STR_KEY_FAV_TRAINS          @"FAV_TRAINS"
#define STR_KEY_FAV_STATIONS        @"FAV_STATIONS"

#define INT_LEFT_NAV_MOVE_DISTANCE      258

#define INT_UPDATE_STATUS_TIMER_DELAY       2.0// TEST_CODE 30.0
#define INT_UPDATE_WALK_DIST_TIMER_DELAY    10.0// TEST_CODE 30.0


#define INT_ALERT_TAG_RETRY             1

#define STR_FOLDER_DATA_FILES           @"DataFiles"


//#define STR_PARSE_APP_ID                @"zvTZXlTzpGnrccEwEXiokp2UJ7ZusYftc4Wt9B0i"
//#define STR_PARSE_CLIENT_KEY            @"pI4IVkAUE5qSym9wmzur0Nn6OhlS1a7p0cqz5s0t"

#define STR_PARSE_APP_ID                @"RbAVcTWNVSPFsEXu1xhfmehMhkeBlZqdeyEcXseS"
#define STR_PARSE_CLIENT_KEY            @"h24351TKlXm2NXeQHUley8dvHyfLEJVAKBWA147e"


#define INT_MAX_STATION_DISTANCE        (3*1609.34)// 3 Miles


#define INT_MAX_SCHEDULED_RECS          10




#define INT_TESTING_LATITUDE            40.821
#define INT_TESTING_LONGITUDE           -73.874


// TEST_CODE

/*
 
If countdownNext becomes >= walkingEstimate then
• vibrate 4 times
• animate the walkingEstimate number
• and display the following notification:
You must start walking now to catch the next train.


*/


@protocol Defines <NSObject>

@end
