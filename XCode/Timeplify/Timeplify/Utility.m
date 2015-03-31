//
//  Utility.m
//  Timeplify
//
//  Created by Anil on 08/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "Utility.h"
#import "Defines.h"
#import <CoreLocation/CoreLocation.h>

@implementation Utility


+(double) getLocationDistance :(double) lat1 : (double) lon1 : (double) lat2 : (double) lon2
{
	CLLocation* loc1 = [[CLLocation alloc] initWithLatitude:lat1 longitude:lon1];
	CLLocation* loc2 = [[CLLocation alloc] initWithLatitude:lat2 longitude:lon2];
	
	double dbDist =  [loc1 distanceFromLocation:loc2];
	return dbDist;
}

+(void) rateThisApp
{
    NSString* strAppID = STR_APP_STORE_ID;
    
    NSString* iOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%@";
    NSString* iOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@";
    
    
    
    NSString* strURL = [NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)? iOS7AppStoreURLFormat: iOSAppStoreURLFormat, strAppID];
    
    NSURL* oURL =[NSURL URLWithString:strURL];
    
    [[UIApplication sharedApplication] openURL:oURL];
}


+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    //  [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}



+(void) saveDictInDefault:(NSString*)IN_strKey :(NSMutableDictionary*) IN_Dict
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:IN_Dict forKey:IN_strKey];
	[defaults  synchronize];
}

+(NSMutableDictionary*) getDictFromDefault:(NSString*)IN_strKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary* oD1 = [defaults objectForKey:IN_strKey];
    
    if (oD1 == nil) {
        return nil;
    }
    NSMutableDictionary* oD2 = [[NSMutableDictionary alloc] initWithDictionary:oD1];
    return oD2;    
}



+(NSString*) createAndGetAFolder:(NSString*) IN_strFolder
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *strDirectory = [paths objectAtIndex:0];
	
	NSString* strFolder = [strDirectory stringByAppendingPathComponent:IN_strFolder];
	
	
	[[NSFileManager defaultManager] createDirectoryAtPath:strFolder
							  withIntermediateDirectories:NO attributes:nil error:nil];
	
	return strFolder;
}

+(void) saveStringInDefault:(NSString*)IN_strKey :(NSString*) IN_strValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:IN_strValue forKey:IN_strKey];
	[defaults  synchronize];
}

+(NSString*) getStringFromDefault:(NSString*)IN_strKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* strVal = [defaults objectForKey:IN_strKey];
    
    if (strVal == nil) {
        strVal =@"";
    }
    
    return strVal;
    
}

+(NSString*) getFilePathForKey:(NSString*) IN_strKey
{
    NSString* strFolder = [Utility createAndGetAFolder:STR_FOLDER_DATA_FILES];
    NSString* strFile = [NSString stringWithFormat:@"%@.plist", IN_strKey];
    NSString* strFullPath = [strFolder stringByAppendingPathComponent:strFile];
    return strFullPath;
    
}

+(void) saveObjectInDefault:(NSString*)IN_strKey :(NSObject*) IN_oData
{
    NSData *archivedObject = [NSKeyedArchiver archivedDataWithRootObject:IN_oData];
    
    NSString* strPath = [Utility getFilePathForKey:IN_strKey];
    NSLog(@"Path '%@'", strPath);
    
    [[NSFileManager defaultManager] removeItemAtPath:strPath error:nil];
    [archivedObject writeToFile:strPath atomically:YES];

    
}
+(NSObject*) getObjectFromDefault:(NSString*)IN_strKey
{
    NSString* strPath = [Utility getFilePathForKey:IN_strKey];
    NSLog(@"Path '%@'", strPath);
    
    NSData *archivedObject = [NSData dataWithContentsOfFile:strPath];
    if (archivedObject == nil) {
        return nil;
    }
    
    NSObject *obj = (NSObject*)[NSKeyedUnarchiver unarchiveObjectWithData:archivedObject];
    return obj;
}

+(BOOL) isDeviceiPhone5
{
    BOOL bFive  =NO;
    
    CGRect oRect = [[UIScreen mainScreen] bounds];
    
    if ((oRect.size.height > 560.0)&& (oRect.size.height < 570.0)){
        bFive = YES;
    }
    
    return bFive;
}

+(NSDate*) getDateWithoutTime:(NSDate*)IN_Date
{
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
	unsigned int unitFlags = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit | NSHourCalendarUnit	| NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *conversionInfo = [sysCalendar components:unitFlags fromDate:IN_Date];
	
	int iYear = (int)[conversionInfo year];
    int iMonth = (int)[conversionInfo month];
    int iDay = (int)[conversionInfo day];
    
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateFormat:@"yyyy MM dd HH:mm:ss"];
	NSString *dateString = [NSString stringWithFormat:@"%4d %2d %2d %2d:%2d:%2d", iYear, iMonth, iDay, 0, 0, 0];
    
    NSDate* oDateReturn = [format dateFromString:dateString];
    return oDateReturn;

}


@end
