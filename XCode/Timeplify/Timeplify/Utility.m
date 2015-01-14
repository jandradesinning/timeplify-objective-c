//
//  Utility.m
//  Timeplify
//
//  Created by Anil on 08/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "Utility.h"
#import "Defines.h"

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




@end
