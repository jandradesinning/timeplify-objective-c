//
//  Utility.h
//  Timeplify
//
//  Created by Anil on 08/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject
{
    
}
+(double) getLocationDistance :(double) lat1 : (double) lon1 : (double) lat2 : (double) lon2;
+(void) rateThisApp;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
+(void) saveDictInDefault:(NSString*)IN_strKey :(NSMutableDictionary*) IN_strValue;
+(NSMutableDictionary*) getDictFromDefault:(NSString*)IN_strKey;
+(BOOL) isDeviceiPhone5;
+(void) saveStringInDefault:(NSString*)IN_strKey :(NSString*) IN_strValue;
+(NSString*) getStringFromDefault:(NSString*)IN_strKey;
+(void) saveObjectInDefault:(NSString*)IN_strKey :(NSObject*) IN_oData;
+(NSString*) getFilePathForKey:(NSString*) IN_strKey;
+(NSObject*) getObjectFromDefault:(NSString*)IN_strKey;
+(NSString*) createAndGetAFolder:(NSString*) IN_strFolder;
+(NSDate*) getDateWithoutTime:(NSDate*)IN_Date;
@end
