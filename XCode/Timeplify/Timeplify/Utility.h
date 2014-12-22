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
+(BOOL) isDeviceiPhone5;
+(void) saveStringInDefault:(NSString*)IN_strKey :(NSString*) IN_strValue;
+(NSString*) getStringFromDefault:(NSString*)IN_strKey;
+(void) saveObjectInDefault:(NSString*)IN_strKey :(NSObject*) IN_oData;
+(NSObject*) getObjectFromDefault:(NSString*)IN_strKey;
+(NSString*) createAndGetAFolder:(NSString*) IN_strFolder;
@end
