//
//  ViewController.h
//  FSLibIOsObjcDemo
//
//  Created by David on 23.10.19.
//  Copyright © 2019 feelSpace GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FSLibIOs/FSLibIOs-Swift.h>

@interface ViewController : UIViewController <FSNavigationControllerDelegate> {
    // Interface to the belt
    //FSNavigationController *beltController;
}
@property(nonatomic, retain) FSNavigationController *beltController;
//- (void)updateUILabels;


@end

