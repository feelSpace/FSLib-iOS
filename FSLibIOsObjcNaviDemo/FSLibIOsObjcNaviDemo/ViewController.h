//
//  ViewController.h
//  FSLibIOsObjcNaviDemo
//
//  Created by David Meignan on 13.04.18.
//  Copyright © 2018 David Meignan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FSLibIOs/FSLibIOs-Swift.h>

@interface ViewController : UIViewController <FSNavigationSignalDelegate> {
    // Interface to the belt
    FSNavigationSignalController *beltController;
}
@property(nonatomic, retain) FSNavigationSignalController *beltController;
- (void)updateUILabels;

// UI actions
- (IBAction)searchAndConnectPressed:(id)sender;
- (IBAction)disconnectPressed:(id)sender;
- (IBAction)startNavigationPressed:(id)sender;
- (IBAction)stopNavigationPressed:(id)sender;
- (IBAction)pauseNavigationPressed:(id)sender;
- (IBAction)navigationEastPressed:(id)sender;
- (IBAction)navigationNorthEastPressed:(id)sender;
- (IBAction)approachingDestinationPressed:(id)sender;
- (IBAction)destinationReachedPressed:(id)sender;
- (IBAction)notifyDestinationReachedPressed:(id)sender;
- (IBAction)notifyWarningPressed:(id)sender;
- (IBAction)notifyDirectionSouthPressed:(id)sender;

// UI components
@property (weak, nonatomic) IBOutlet UILabel *connectionStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *beltModeLabel;
@property (weak, nonatomic) IBOutlet UILabel *navigationDirectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *signalTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *beltHeadingLabel;

@end

