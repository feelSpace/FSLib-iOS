//
//  ViewController.m
//  FSLibIOsObjcDemo
//
//  Created by David on 23.10.19.
//  Copyright © 2019 feelSpace GmbH. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize beltController;
@synthesize selectedSignalType;

// UI components
@synthesize connectButton;
@synthesize disconnectButton;
@synthesize connectionStateLabel;
@synthesize defaultIntensityLabel;
@synthesize defaultIntensitySlider;
@synthesize beltHeadingLabel;
@synthesize orientationAccurateLabel;
@synthesize changeAccuracySignalButton;
@synthesize powerStatusLabel;
@synthesize batteryLevelLabel;
@synthesize startBatterySignalButton;
@synthesize navigationDirectionLabel;
@synthesize navigationDirectionSlider;
@synthesize magneticBearingSwitch;
@synthesize signalTypeButton;
@synthesize startNavigationButton;
@synthesize pauseNavigationButton;
@synthesize stopNavigationButton;
@synthesize navigationStateLabel;
@synthesize notificationDirectionLabel;
@synthesize notificationDirectionSlider;
@synthesize startBearingNotificationButton;
@synthesize startDirectionNotificationButton;
@synthesize startWarningButton;
@synthesize startCriticalWarningButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Belt controller
    beltController = [[FSNavigationController alloc] init];
    [beltController setDelegate:self];
    // Selected signal type
    selectedSignalType = FSBeltVibrationSignalContinuous;
    // Update UI
    [self updateUI];
}

//MARK: Private methods

- (void)updateUI {
    [self updateConnectionPanel];
    [self updateDefaultIntensityPanel];
    [self updateOrientationPanel];
    [self updateBatteryPanel];
    [self updateNavigationSignalTypePanel];
    [self updateNavigationStatePanel];
}

- (void)updateConnectionPanel {
    switch (beltController.connectionState) {
        case FSBeltConnectionStateNotConnected:
            connectButton.enabled = YES;
            disconnectButton.enabled = NO;
            connectionStateLabel.text = @"Disconnected";
            break;
        case FSBeltConnectionStateSearching:
            connectButton.enabled = NO;
            disconnectButton.enabled = YES;
            connectionStateLabel.text = @"Scanning";
            break;
        case FSBeltConnectionStateConnecting:
            connectButton.enabled = NO;
            disconnectButton.enabled = YES;
            connectionStateLabel.text = @"Connecting";
            break;
//        case FSBeltConnectionStateReconnecting:
//            connectButton.enabled = NO;
//            disconnectButton.enabled = YES;
//            connectionStateLabel.text = @"Reconnecting";
//            break;
//        case FSBeltConnectionStateDiscoveringServices:
//            connectButton.enabled = NO;
//            disconnectButton.enabled = YES;
//            connectionStateLabel.text = @"Discovering services";
//            break;
//        case FSBeltConnectionStateHandshake:
//            connectButton.enabled = NO;
//            disconnectButton.enabled = YES;
//            connectionStateLabel.text = @"Handshake";
//            break;
        case FSBeltConnectionStateConnected:
            connectButton.enabled = NO;
            disconnectButton.enabled = YES;
            connectionStateLabel.text = @"Connected";
            break;
    }
}

- (void)updateDefaultIntensityPanel {
    if (beltController.defaultVibrationIntensity < 0) {
        defaultIntensityLabel.text = @"Unknown";
        [defaultIntensitySlider setValue:50 animated:NO];
        defaultIntensitySlider.enabled = NO;
    } else {
        defaultIntensityLabel.text = [NSString stringWithFormat:@"%ld%%", (long)beltController.defaultVibrationIntensity];
        [defaultIntensitySlider setValue:beltController.defaultVibrationIntensity animated:NO];
        defaultIntensitySlider.enabled = YES;
    }
}

- (void)updateBatteryPanel {
    switch (beltController.beltPowerStatus) {
        case FSPowerStatusUnknown:
            powerStatusLabel.text = @"Unknown";
            break;
        case FSPowerStatusOnBattery:
            powerStatusLabel.text = @"On battery";
            break;
        case FSPowerStatusCharging:
            powerStatusLabel.text = @"Charging";
            break;
        case FSPowerStatusExternalPower:
            powerStatusLabel.text = @"External power supply";
            break;
    }
    if (beltController.beltBatteryLevel < 0) {
        batteryLevelLabel.text = @"Unknown";
    } else {
        batteryLevelLabel.text = [NSString stringWithFormat:@"%ld%%", (long)beltController.beltBatteryLevel];
    }
}

- (void)updateOrientationPanel {
    if (beltController.beltHeading < 0) {
        beltHeadingLabel.text = @"Unknown";
    } else {
        beltHeadingLabel.text = [NSString stringWithFormat:@"%ld°", (long)beltController.beltHeading];
    }
    if (beltController.beltOrientationAccurate < 0) {
        orientationAccurateLabel.text = @"Unknown";
    } else if (beltController.beltOrientationAccurate > 0) {
        orientationAccurateLabel.text = @"Yes";
    } else {
        orientationAccurateLabel.text = @"No";
    }
    if (beltController.compassAccuracySignalEnabled < 0) {
        changeAccuracySignalButton.enabled = NO;
        [changeAccuracySignalButton setTitle:@"Unknown accuracy signal state" forState:UIControlStateNormal];
    } else if (beltController.compassAccuracySignalEnabled > 0) {
        changeAccuracySignalButton.enabled = YES;
        [changeAccuracySignalButton setTitle:@"Disable accuracy signal" forState:UIControlStateNormal];
    } else {
        changeAccuracySignalButton.enabled = YES;
        [changeAccuracySignalButton setTitle:@"Enable accuracy signal" forState:UIControlStateNormal];
    }
}

- (void)updateNavigationSignalTypePanel {
    switch (selectedSignalType) {
        case FSBeltVibrationSignalNoVibration:
            [signalTypeButton setTitle:@"No vibration" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalContinuous:
            [signalTypeButton setTitle:@"Continuous" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalNavigation:
            [signalTypeButton setTitle:@"Navigation signal" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalApproachingDestination:
            [signalTypeButton setTitle:@"Approaching destination" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalTurnOngoing:
            [signalTypeButton setTitle:@"Ongoing turn" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalDirectionNotification:
            [signalTypeButton setTitle:@"Illegal signal type" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalNextWaypointLongDistance:
            [signalTypeButton setTitle:@"Next waypoint at long distance" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalNextWaypointMediumDistance:
            [signalTypeButton setTitle:@"Next waypoint at medium distance" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalNextWaypointShortDistance:
            [signalTypeButton setTitle:@"Next waypoint at short distance" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalNextWaypointAreaReached:
            [signalTypeButton setTitle:@"Waypoint area reached" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalDestinationReachedRepeated:
            [signalTypeButton setTitle:@"Destination reached" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalDestinationReachedSingle:
            [signalTypeButton setTitle:@"Illegal signal type" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalOperationWarning:
            [signalTypeButton setTitle:@"Illegal signal type" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalCriticalWarning:
            [signalTypeButton setTitle:@"Illegal signal type" forState:UIControlStateNormal];
            break;
        case FSBeltVibrationSignalBatteryLevel:
            [signalTypeButton setTitle:@"Illegal signal type" forState:UIControlStateNormal];
            break;
    }
}

- (void)updateNavigationStatePanel {
    switch (beltController.navigationState) {
        case FSNavigationStateStopped:
            navigationStateLabel.text = @"Stopped";
            break;
        case FSNavigationStatePaused:
            navigationStateLabel.text = @"Paused";
            break;
        case FSNavigationStateNavigating:
            navigationStateLabel.text = @"Navigating";
            break;
    }
}

- (void)setSignalType:(FSBeltVibrationSignal)selected {
    selectedSignalType = selected;
    [self updateNavigationSignalTypePanel];
    (void)[beltController updateNavigationSignalWithDirection:(int)navigationDirectionSlider.value isMagneticBearing:magneticBearingSwitch.on signal:selectedSignalType];
}

// Code from: https://stackoverflow.com/a/46728731
- (void)showToast:(NSString*)Message {
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:nil
                                                                  message:@""
                                                           preferredStyle:UIAlertControllerStyleAlert];
    UIView *firstSubview = alert.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    for (UIView *subSubView in alertContentView.subviews) {
        subSubView.backgroundColor = [UIColor colorWithRed:141/255.0f green:0/255.0f blue:254/255.0f alpha:1.0f];
    }
    NSMutableAttributedString *AS = [[NSMutableAttributedString alloc] initWithString:Message];
    [AS addAttribute: NSForegroundColorAttributeName value: [UIColor whiteColor] range: NSMakeRange(0,AS.length)];
    [alert setValue:AS forKey:@"attributedTitle"];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:^{
        }];
    });
}


//MARK: UI Event handlers

- (IBAction)onConnectButtonTap:(id)sender{
    if (beltController.connectionState == FSBeltConnectionStateNotConnected) {
        [beltController searchAndConnectBelt];
    }
}

- (IBAction)onDisconnectButtonTap:(id)sender{
    if (beltController.connectionState != FSBeltConnectionStateNotConnected) {
        [beltController disconnectBelt];
    }
}

- (IBAction)onDefaultIntensitySliderValueChanged:(id)sender{
    defaultIntensityLabel.text = [NSString stringWithFormat:@"%d%%", (int)defaultIntensitySlider.value];
}

- (IBAction)onDefaultIntensitySliderReleased:(id)sender{
    if (beltController.connectionState == FSBeltConnectionStateConnected) {
        (void)[beltController changeDefaultVibrationIntensityWithIntensity:(int)defaultIntensitySlider.value vibrationFeedback:YES];
    }
}

- (IBAction)onDefaultIntensitySliderReleasedOutside:(id)sender{
    [self onDefaultIntensitySliderReleased:sender];
}

- (IBAction)onChangeAccuracySignalButtonTap:(id)sender{
    //MARK: TODO
    [self showToast:@"UI not yet implemented."];
}

- (IBAction)onStartBatterySignalButtonTap:(id)sender{
    if (beltController.connectionState == FSBeltConnectionStateConnected) {
        (void)[beltController notifyBeltBatteryLevel];
    }
}

- (IBAction)onNavigationDirectionSliderValueChanged:(id)sender{
    navigationDirectionLabel.text = [NSString stringWithFormat:@"%d°", (int)navigationDirectionSlider.value];
    (void)[beltController updateNavigationSignalWithDirection:(int)navigationDirectionSlider.value isMagneticBearing:magneticBearingSwitch.on signal:selectedSignalType];
}

- (IBAction)onMagneticBearingSwitchValueChanged:(id)sender{
    (void)[beltController updateNavigationSignalWithDirection:(int)navigationDirectionSlider.value isMagneticBearing:magneticBearingSwitch.on signal:selectedSignalType];
}

- (IBAction)onSignalTypeButtonTap:(id)sender{
    //MARK: TODO
    [self showToast:@"UI not yet implemented."];
}

- (IBAction)onStartNavigationButtonTap:(id)sender{
    (void)[beltController startNavigationWithDirection:(int)navigationDirectionSlider.value isMagneticBearing:magneticBearingSwitch.on signal:selectedSignalType];
}

- (IBAction)onPauseNavigationButtonTap:(id)sender{
    [beltController pauseNavigation];
}

- (IBAction)onStopNavigationButtonTap:(id)sender{
    [beltController stopNavigation];
}

- (IBAction)onNotificationDirectionSliderValueChanged:(id)sender{
    notificationDirectionLabel.text = [NSString stringWithFormat:@"%d°", (int)notificationDirectionSlider.value];
}

- (IBAction)onStartBearingNotificationButtonTap:(id)sender{
    if (beltController.connectionState == FSBeltConnectionStateConnected) {
        (void)[beltController notifyDirectionWithDirection:(int)notificationDirectionSlider.value isMagneticBearing:YES];
    }
}

- (IBAction)onStartDirectionNotificationButtonTap:(id)sender{
    if (beltController.connectionState == FSBeltConnectionStateConnected) {
        (void)[beltController notifyDirectionWithDirection:(int)notificationDirectionSlider.value isMagneticBearing:NO];
    }
}

- (IBAction)onStartWarningButtonTap:(id)sender{
    if (beltController.connectionState == FSBeltConnectionStateConnected) {
        [beltController notifyWarningWithCritical:NO];
    }
}

- (IBAction)onStartCriticalWarningButtonTap:(id)sender{
    if (beltController.connectionState == FSBeltConnectionStateConnected) {
        [beltController notifyWarningWithCritical:YES];
    }
}


//MARK: Delegate methods implementation

- (void)onBeltBatteryLevelUpdatedWithBatteryLevel:(NSInteger)batteryLevel status:(enum FSPowerStatus)status {
    [self updateBatteryPanel];
}

//- (void)onBeltConnectionFailed {
//    [self showToast:@"Connection failed!"];
//}
//
//- (void)onBeltConnectionLost {
//    [self showToast:@"Connection lost!"];
//}
//
//- (void)onBeltConnectionStateChangedWithState:(enum FSBeltConnectionState)state {
//    [self updateUI];
//}

- (void)onBeltDefaultVibrationIntensityChangedWithIntensity:(NSInteger)intensity {
    [self updateDefaultIntensityPanel];
}

- (void)onBeltHomeButtonPressedWithNavigating:(BOOL)navigating {
    [self showToast:@"Home button pressed!"];
}

- (void)onBeltOrientationUpdatedWithBeltHeading:(NSInteger)beltHeading accurate:(BOOL)accurate {
    [self updateOrientationPanel];
}

//- (void)onBluetoothNotAvailable {
//    [self showToast:@"No Bluetooth available!"];
//}
//
//- (void)onBluetoothPoweredOff {
//    [self showToast:@"Please turn on Bluetooth!"];
//}
//
- (void)onCompassAccuracySignalStateUpdatedWithEnabled:(BOOL)enabled {
    [self updateOrientationPanel];
}

- (void)onNavigationStateChangeWithState:(enum FSNavigationState)state {
    [self updateUI];
}
//
//- (void)onNoBeltFound {
//    [self showToast:@"No belt found!"];
//}


- (void)onBeltFoundWithBelt:(CBPeripheral * _Nonnull)belt status:(enum FSBeltConnectionStatus)status {
    // Nothing to do
}


- (void)onConnectionStateChangedWithState:(enum FSBeltConnectionState)state error:(enum FSBeltConnectionError)error {
    [self updateUI];
    switch (error) {
        
        case FSBeltConnectionErrorNoError:
            // Nothing to do
            break;
        case FSBeltConnectionErrorBtPoweredOff:
            [self showToast:@"BT powered off!"];
            break;
        case FSBeltConnectionErrorBtUnauthorized:
            [self showToast:@"BT unauthorized!"];
            break;
        case FSBeltConnectionErrorBtUnsupported:
            [self showToast:@"BT unsupported!"];
            break;
        case FSBeltConnectionErrorBtStateError:
            [self showToast:@"BT not ready!"];
            break;
        case FSBeltConnectionErrorUnexpectedDisconnection:
            [self showToast:@"Unexpected disconnection!"];
            break;
        case FSBeltConnectionErrorNoBeltFound:
            [self showToast:@"No belt found!"];
            break;
        case FSBeltConnectionErrorConnectionTimeout:
            [self showToast:@"Connection timeout!"];
            break;
        case FSBeltConnectionErrorConnectionFailed:
            [self showToast:@"Connection failed!"];
            break;
        case FSBeltConnectionErrorConnectionLimitReached:
            [self showToast:@"Too many BT devices!"];
            break;
        case FSBeltConnectionErrorBeltDisconnection:
            [self showToast:@"Belt disconnected!"];
            break;
        case FSBeltConnectionErrorBeltPoweredOff:
            [self showToast:@"Belt powered off."];
            break;
        case FSBeltConnectionErrorPairingPermissionError:
            [self showToast:@"Pairing error!"];
            break;
    }
    
}


@end
