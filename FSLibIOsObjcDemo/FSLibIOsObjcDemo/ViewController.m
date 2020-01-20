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
    selectedSignalType = FSBeltVibrationSignalNoVibration;
    // Update UI
    [self updateUI];
}

//MARK: Private methods

- (void)updateUI {
    //MARK: TODO
}

- (void)updateConnectionPanel {
    //MARK: TODO
}

- (void)updateDefaultIntensityPanel {
    //MARK: TODO
}

- (void)updateBatteryPanel {
    //MARK: TODO
}

- (void)updateOrientationPanel {
    //MARK: TODO
}

- (void)updateNavigationSignalTypePanel {
    //MARK: TODO
}

- (void)updateNavigationStatePanel {
    //MARK: TODO
}

- (void)setSignalType:(FSBeltVibrationSignal)selected {
    //MARK: TODO
}

- (void)showToast:(NSString*)message {
    //MARK: TODO
}


//MARK: UI Event handlers

- (IBAction)onConnectButtonTap:(id)sender{
    [beltController searchAndConnectBelt];
}

- (IBAction)onDisconnectButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onDefaultIntensitySliderValueChanged:(id)sender{
    //MARK: TODO
}

- (IBAction)onDefaultIntensitySliderReleased:(id)sender{
    //MARK: TODO
}

- (IBAction)onDefaultIntensitySliderReleasedOutside:(id)sender{
    //MARK: TODO
}

- (IBAction)onChangeAccuracySignalButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onStartBatterySignalButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onNavigationDirectionSliderValueChanged:(id)sender{
    //MARK: TODO
}

- (IBAction)onMagneticBearingSwitchValueChanged:(id)sender{
    //MARK: TODO
}

- (IBAction)onSignalTypeButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onStartNavigationButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onPauseNavigationButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onStopNavigationButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onNotificationDirectionSliderValueChanged:(id)sender{
    //MARK: TODO
}

- (IBAction)onStartBearingNotificationButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onStartDirectionNotificationButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onStartWarningButtonTap:(id)sender{
    //MARK: TODO
}

- (IBAction)onStartCriticalWarningButtonTap:(id)sender{
    //MARK: TODO
}


//MARK: Delegate methods implementation

- (void)onBeltBatteryLevelUpdatedWithBatteryLevel:(NSInteger)batteryLevel status:(enum FSPowerStatus)status {
    //TODO: TBI
}

- (void)onBeltConnectionFailed {
    //TODO: TBI
}

- (void)onBeltConnectionLost {
    //TODO: TBI
}

- (void)onBeltConnectionStateChangedWithState:(enum FSBeltConnectionState)state {
    //TODO: TBI
}

- (void)onBeltDefaultVibrationIntensityChangedWithIntensity:(NSInteger)intensity {
    //TODO: TBI
}

- (void)onBeltHomeButtonPressedWithNavigating:(BOOL)navigating {
    //TODO: TBI
}

- (void)onBeltOrientationUpdatedWithBeltHeading:(NSInteger)beltHeading accurate:(BOOL)accurate {
    //TODO: TBI
}

- (void)onBluetoothNotAvailable {
    //TODO: TBI
}

- (void)onBluetoothPoweredOff {
    //TODO: TBI
}

- (void)onCompassAccuracySignalStateUpdatedWithEnabled:(BOOL)enabled {
    //TODO: TBI
}

- (void)onNavigationStateChangeWithState:(enum FSNavigationState)state {
    //TODO: TBI
}

- (void)onNoBeltFound {
    //TODO: TBI
}

@end
