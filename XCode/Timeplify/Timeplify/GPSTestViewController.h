//
//  GPSTestViewController.h
//  Timeplify
//
//  Created by Anil on 13/12/14.
//  Copyright (c) 2014 Anil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface GPSTestViewController : UIViewController <MKMapViewDelegate>
{
    IBOutlet MKMapView * m_ctrlMap;
    
    IBOutlet UILabel* m_ctrlLblTitle;
}

-(IBAction) btnBackClicked:(id)sender;
-(IBAction) btnDefClicked:(id)sender;
@end
