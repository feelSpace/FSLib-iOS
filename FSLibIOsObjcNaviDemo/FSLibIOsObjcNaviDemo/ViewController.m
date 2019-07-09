//
//  ViewController.m
//  FSLibIOsObjcNaviDemo
//
//  Created by David Meignan on 13.04.18.
//  Copyright © 2018 David Meignan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize beltController;

@synthesize connectionStateLabel;
@synthesize beltModeLabel;
@synthesize navigationDirectionLabel;
@synthesize signalTypeLabel;
@synthesize beltHeadingLabel;

// *** ViewController implementation ***

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize belt controller
    beltController = [[FSNavigationSignalController alloc] init];
    [beltController setDelegate:self];
    
    // Update UI
    [self updateUILabels];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// *** Private methods ***

- (void)updateUILabels {
    
    // Update connection state label
    switch (beltController.connectionState) {
        case FSScanConnectionStateScanning:
            connectionStateLabel.text = @"Connection state: Scanning";
            break;
        case FSScanConnectionStateConnected:
            connectionStateLabel.text = @"Connection state: Connected";
            break;
        case FSScanConnectionStateConnecting:
            connectionStateLabel.text = @"Connection state: Connecting";
            break;
        case FSScanConnectionStateNotConnected:
            connectionStateLabel.text = @"Connection state: Disconnected";
            break;
    }
    
    // Belt mode label
    switch (beltController.beltMode) {
        case FSBeltSignalModeWait:
            beltModeLabel.text = @"Belt mode: Wait";
            break;
        case FSBeltSignalModePause:
            beltModeLabel.text = @"Belt mode: Pause";
            break;
        case FSBeltSignalModeCompass:
            beltModeLabel.text = @"Belt mode: Compass";
            break;
        case FSBeltSignalModeUnknown:
            beltModeLabel.text = @"Belt mode: Unknown";
            break;
        case FSBeltSignalModeNavigation:
            beltModeLabel.text = @"Belt mode: Navigation";
            break;
    }
    
    // Navigation direction label
    if (beltController.activeNavigationDirection == nil) {
        navigationDirectionLabel.text = @"Navigation direction: -";
    } else {
        navigationDirectionLabel.text = [NSString stringWithFormat:@"Navigation direction: %d", beltController.activeNavigationDirection.intValue];
    }
    
    // Signal type label
    switch (beltController.activeNavigationSignalType) {
        case FSNavigationSignalTypeNavigating:
            signalTypeLabel.text = @"Signal type: Navigating";
            break;
        case FSNavigationSignalTypeApproachingDestination:
            signalTypeLabel.text = @"Signal type: Approaching destination";
            break;
        case FSNavigationSignalTypeDestinationReached:
            signalTypeLabel.text = @"Signal type: Destination reached";
            break;
    }
    
    // Belt heading
    if (beltController.beltMagHeading == nil || beltController.beltCompassInaccurate == nil) {
        beltHeadingLabel.text = @"Belt heading: -";
    } else {
        if (beltController.beltCompassInaccurate) {
            [beltHeadingLabel setText:[NSString stringWithFormat:@"Belt heading: %d (Inaccurate!)", beltController.beltMagHeading.intValue]];
        } else {
            [beltHeadingLabel setText:[NSString stringWithFormat:@"Belt heading: %d", beltController.beltMagHeading.intValue]];
        }
    }
}

// *** UI event handlers ***

- (IBAction)searchAndConnectPressed:(id)sender {
    [beltController searchAndConnectBelt];
}

- (IBAction)disconnectPressed:(id)sender {
    [beltController disconnectBelt];
}

- (IBAction)startNavigationPressed:(id)sender {
    [beltController startNavigation];
    [self updateUILabels];
}

- (IBAction)stopNavigationPressed:(id)sender {
    [beltController stopNavigation];
    [self updateUILabels];
}

- (IBAction)pauseNavigationPressed:(id)sender {
    [beltController pauseNavigation];
    [self updateUILabels];
}

- (IBAction)navigationEastPressed:(id)sender {
    [beltController setNavigationDirection:[NSNumber numberWithInt:90] signalType:FSNavigationSignalTypeNavigating];
    [self updateUILabels];
}

- (IBAction)navigationNorthEastPressed:(id)sender {
    [beltController setNavigationDirection:[NSNumber numberWithInt:45] signalType:FSNavigationSignalTypeNavigating];
    [self updateUILabels];
}

- (IBAction)approachingDestinationPressed:(id)sender {
    [beltController setNavigationDirection:[NSNumber numberWithInt:0] signalType:FSNavigationSignalTypeApproachingDestination];
    [self updateUILabels];
}

- (IBAction)destinationReachedPressed:(id)sender {
    [beltController setNavigationDirection:[NSNumber numberWithInt:0] signalType:FSNavigationSignalTypeDestinationReached];
    [self updateUILabels];
}

- (IBAction)notifyDestinationReachedPressed:(id)sender {
    [beltController notifyDestinationReachedWithShouldStopNavigation:true];
}

- (IBAction)notifyWarningPressed:(id)sender {
    [beltController notifyWarning];
}

- (IBAction)notifyBatteryPressed:(UIButton *)sender {
    
}


- (IBAction)notifyDirectionSouthPressed:(id)sender {
    [beltController notifyDirection:180];
}

// *** FSNavigationSignalDelegate implementation ***

- (void)onBeltRequestHome {
    printf("Home request received. Start navigation to West.\n");
    [beltController setNavigationDirection:[NSNumber numberWithInt:270] signalType:FSNavigationSignalTypeNavigating];
    [beltController startNavigation];
    [self updateUILabels];
}

- (void)onBeltSignalModeChangedWithBeltMode:(enum FSBeltSignalMode)beltMode buttonPressed:(BOOL)buttonPressed {
    printf("Belt mode changed.\n");
    [self updateUILabels];
}

- (void)onScanConnectionStateChangedWithPreviousState:(enum FSScanConnectionState)previousState newState:(enum FSScanConnectionState)newState {
    printf("Connection state changed.\n");
    [self updateUILabels];
}

- (void)onBeltOrientationNotifiedWithBeltMagHeading:(NSInteger)beltMagHeading beltCompassInaccurate:(BOOL)calibrationRequired {
    [self updateUILabels];
}


@end

