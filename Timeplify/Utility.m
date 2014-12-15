//
//  Utility.m
//  Timeplify
//
//  Created by Anil on 08/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "Utility.h"

@implementation Utility


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

+(void) saveObjectInDefault:(NSString*)IN_strKey :(NSObject*) IN_oData
{
    NSData *archivedObject = [NSKeyedArchiver archivedDataWithRootObject:IN_oData];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:archivedObject forKey:IN_strKey];
    [defaults synchronize];
}
+(NSObject*) getObjectFromDefault:(NSString*)IN_strKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *archivedObject = [defaults objectForKey:IN_strKey];
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




@end
