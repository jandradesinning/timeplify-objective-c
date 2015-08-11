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

#define INT_DIRECTION_NORTH             1
#define INT_DIRECTION_SOUTH             2
#define INT_DIRECTION_EITHER            3

#define STR_DIRECTION_NORTH             @"North"
#define STR_DIRECTION_SOUTH             @"South"
#define STR_DIRECTION_EITHER            @"Either"


#define INT_FLOW_COVER_SIZE             0.205047
#define INT_FLOW_COVER_SPREAD           0.328076
#define INT_FLOW_COVER_ZOOM             0.225552

#define INT_STATION_SEL_FROM_WELCOME    1
#define INT_STATION_SEL_FROM_SEE_ALL    2
#define INT_STATION_SEL_FROM_FAV        3


#define STR_KEY_FAV_TRAINS              @"FAV_TRAINS"
#define STR_KEY_FAV_STATIONS            @"FAV_STATIONS"

#define INT_LEFT_NAV_MOVE_DISTANCE      258

#define INT_UPDATE_STATUS_TIMER_DELAY               1.0
#define INT_UPDATE_SERVER_RECALL_TIMER_DELAY        30.0

#define INT_UPDATE_SERVICE_STATUS_DELAY             60.0


#define INT_ALERT_TAG_RETRY                 1
#define INT_ALERT_TAG_NO_STATION_IN_RADIUS  2

#define STR_FOLDER_DATA_FILES           @"DataFiles"


//TEST     // TEST_CODE
//#define STR_PARSE_APP_ID              @"zvTZXlTzpGnrccEwEXiokp2UJ7ZusYftc4Wt9B0i"
//#define STR_PARSE_CLIENT_KEY          @"pI4IVkAUE5qSym9wmzur0Nn6OhlS1a7p0cqz5s0t"


//LIVE
#define STR_PARSE_APP_ID                @"RbAVcTWNVSPFsEXu1xhfmehMhkeBlZqdeyEcXseS"
#define STR_PARSE_CLIENT_KEY            @"h24351TKlXm2NXeQHUley8dvHyfLEJVAKBWA147e"


#define INT_MAX_STATION_DISTANCE        (1*1609.34)// currently 1 mile  3 Miles = (3*1609.34)
#define INT_MAX_SCHEDULED_RECS          10

#define INT_TESTING_LATITUDE            40.821
#define INT_TESTING_LONGITUDE           -73.874

#define INT_GPS_ACCURACY                250


#define STR_APP_STORE_ID                @"893213536"

#define INT_GPS_NOTIFY_MIN_DISTANCE     100 // TEST_CODE 100


#define INT_VIBRATE_TIMES               4
#define INT_ZERO_BLINK_TIMES            60  // TEST_CODE 60
#define INT_JUST_LEFT_BLINK_TIMES       20  // TEST_CODE 20


// TEST_CODE

@protocol Defines <NSObject>

@end
