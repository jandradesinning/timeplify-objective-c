//
//  GlobalCaller.m
//  Timeplify
//
//  Created by Anil on 08/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import "GlobalCaller.h"
#import "AppDelegate.h"

@implementation GlobalCaller

+(NSMutableArray*) getFavTrainsArray
{
    AppDelegate* appDel = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    return appDel.m_arrFavoriteTrains;
    
}
@end
