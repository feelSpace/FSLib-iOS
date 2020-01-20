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
    FSNavigationController *beltController;
}

// Properties
@property(nonatomic, retain) FSNavigationController *beltController;
@property(nonatomic, assign) FSBeltVibrationSignal selectedSignalType;

// UI components
@property(weak, nonatomic) IBOutlet UIButton *connectButton;
@property(weak, nonatomic) IBOutlet UIButton *disconnectButton;
@property(weak, nonatomic) IBOutlet UILabel *connectionStateLabel;
@property(weak, nonatomic) IBOutlet UILabel *defaultIntensityLabel;
@property(weak, nonatomic) IBOutlet UISlider *defaultIntensitySlider;
@property(weak, nonatomic) IBOutlet UILabel *beltHeadingLabel;
@property(weak, nonatomic) IBOutlet UILabel *orientationAccurateLabel;
@property(weak, nonatomic) IBOutlet UIButton *changeAccuracySignalButton;
@property(weak, nonatomic) IBOutlet UILabel *powerStatusLabel;
@property(weak, nonatomic) IBOutlet UILabel *batteryLevelLabel;
@property(weak, nonatomic) IBOutlet UIButton *startBatterySignalButton;
@property(weak, nonatomic) IBOutlet UILabel *navigationDirectionLabel;
@property(weak, nonatomic) IBOutlet UISlider *navigationDirectionSlider;
@property(weak, nonatomic) IBOutlet UISwitch *magneticBearingSwitch;
@property(weak, nonatomic) IBOutlet UIButton *signalTypeButton;
@property(weak, nonatomic) IBOutlet UIButton *startNavigationButton;
@property(weak, nonatomic) IBOutlet UIButton *pauseNavigationButton;
@property(weak, nonatomic) IBOutlet UIButton *stopNavigationButton;
@property(weak, nonatomic) IBOutlet UILabel *navigationStateLabel;
@property(weak, nonatomic) IBOutlet UILabel *notificationDirectionLabel;
@property(weak, nonatomic) IBOutlet UISlider *notificationDirectionSlider;
@property(weak, nonatomic) IBOutlet UIButton *startBearingNotificationButton;
@property(weak, nonatomic) IBOutlet UIButton *startDirectionNotificationButton;
@property(weak, nonatomic) IBOutlet UIButton *startWarningButton;
@property(weak, nonatomic) IBOutlet UIButton *startCriticalWarningButton;

// Private methods
- (void)updateUI;
- (void)updateConnectionPanel;
- (void)updateDefaultIntensityPanel;
- (void)updateBatteryPanel;
- (void)updateOrientationPanel;
- (void)updateNavigationSignalTypePanel;
- (void)updateNavigationStatePanel;
- (void)setSignalType:(FSBeltVibrationSignal)selected;
- (void)showToast:(NSString*)message;

// UI event handlers
- (IBAction)onConnectButtonTap:(id)sender;
- (IBAction)onDisconnectButtonTap:(id)sender;
- (IBAction)onDefaultIntensitySliderValueChanged:(id)sender;
- (IBAction)onDefaultIntensitySliderReleased:(id)sender;
- (IBAction)onDefaultIntensitySliderReleasedOutside:(id)sender;
- (IBAction)onChangeAccuracySignalButtonTap:(id)sender;
- (IBAction)onStartBatterySignalButtonTap:(id)sender;
- (IBAction)onNavigationDirectionSliderValueChanged:(id)sender;
- (IBAction)onMagneticBearingSwitchValueChanged:(id)sender;
- (IBAction)onSignalTypeButtonTap:(id)sender;
- (IBAction)onStartNavigationButtonTap:(id)sender;
- (IBAction)onPauseNavigationButtonTap:(id)sender;
- (IBAction)onStopNavigationButtonTap:(id)sender;
- (IBAction)onNotificationDirectionSliderValueChanged:(id)sender;
- (IBAction)onStartBearingNotificationButtonTap:(id)sender;
- (IBAction)onStartDirectionNotificationButtonTap:(id)sender;
- (IBAction)onStartWarningButtonTap:(id)sender;
- (IBAction)onStartCriticalWarningButtonTap:(id)sender;

@end

